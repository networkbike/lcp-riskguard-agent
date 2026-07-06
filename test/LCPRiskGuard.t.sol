// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

/// @title LCPRiskGuard runner output-shape test
/// @notice Validates the JSON output shape produced by scripts/run.sh
///         by parsing the runner's stdout and asserting on the structure.
/// @dev This test does NOT exercise the runner itself (which is bash).
///      Instead, it captures the runner's output and asserts that the
///      JSON conforms to the documented schema (see
///      references/output-schema.md). This is a Solidity-level guard
///      that catches regressions in the runner's output shape.
///
/// To run:
///   1. The test scripts at test/capture-output.sh produces
///      test/fixtures/sample-output.json by invoking the runner against
///      a mocked LCP Skill.
///   2. forge test loads the fixture and parses it as a struct.
///
/// The fixture file is committed to the repo so forge test works
/// without RPC access. To regenerate it idx runner changes:
///   bash test/capture-output.sh
contract LCPRiskGuardTest is Test {
    /// @dev Parsed snapshot of the runner's output. Mirrors the JSON
    ///      contract documented in references/output-schema.md.
    struct RunnerOutput {
        string target;
        string network;
        uint256 score;
        string band;
        uint256 pCrisis; // 1e18 scaled
        uint256 blockNumber; // 0 means null
        string timestamp;
        string skill;
        string skillVersion;
        bool filtered; // true if the runner filtered the result
    }

    string internal constant FIXTURE_PATH = "test/fixtures/sample-output.json";

    function _loadFixture() internal view returns (RunnerOutput memory out) {
        string memory json = vm.readFile(FIXTURE_PATH);
        // Parse target.
        out.target = vm.parseJsonString(json, ".target");
        // Parse network.
        out.network = vm.parseJsonString(json, ".network");
        // Parse score (may be 0 in filtered output; we'll use band to tell).
        out.score = vm.parseJsonUint(json, ".score");
        // Parse band.
        out.band = vm.parseJsonString(json, ".band");
        // Parse p_crisis (we'll scale to 1e18 for fixed-point).
        out.pCrisis = vm.parseJsonUint(json, ".p_crisis_e18");
        // Parse block (0 means null).
        out.blockNumber = vm.parseJsonUint(json, ".block");
        // Parse timestamp.
        out.timestamp = vm.parseJsonString(json, ".timestamp");
        // Parse skill.
        out.skill = vm.parseJsonString(json, ".skill");
        // Parse skill_version.
        out.skillVersion = vm.parseJsonString(json, ".skill_version");
        // Parse filtered (default false).
        out.filtered = _readBoolOr(json, ".filtered", false);
    }

    /// @notice Read an optional boolean from a JSON string by
    ///         scanning the raw text for `"<key>": true` or
    ///         `"<key>": false` (with optional whitespace).
    /// @dev We strip the leading "." from forge-std's key path
    ///      convention before scanning.
    function _readBoolOr(string memory json, string memory key, bool defaultValue)
        internal
        pure
        returns (bool)
    {
        bytes memory j = bytes(json);
        bytes memory k = bytes(key);
        // Strip the leading "." (forge-std's path separator).
        bytes memory rawKey = new bytes(k.length > 0 ? k.length - 1 : 0);
        for (uint256 i = 1; i < k.length; i++) {
            rawKey[i - 1] = k[i];
        }
        bytes memory needleTrue = bytes.concat(
            bytes('"'), rawKey, bytes('": true')
        );
        bytes memory needleFalse = bytes.concat(
            bytes('"'), rawKey, bytes('": false')
        );
        bytes memory needleTrueSpaced = bytes.concat(
            bytes('"'), rawKey, bytes('":true')
        );
        bytes memory needleFalseSpaced = bytes.concat(
            bytes('"'), rawKey, bytes('":false')
        );
        if (_containsBytes(j, needleTrue) || _containsBytes(j, needleTrueSpaced)) return true;
        if (_containsBytes(j, needleFalse) || _containsBytes(j, needleFalseSpaced)) return false;
        return defaultValue;
    }

    /// @notice Simple substring search.
    function _containsBytes(bytes memory haystack, bytes memory needle)
        internal
        pure
        returns (bool)
    {
        if (needle.length == 0) return true;
        if (needle.length > haystack.length) return false;
        for (uint256 i = 0; i + needle.length <= haystack.length; i++) {
            bool found = true;
            for (uint256 x = 0; x < needle.length; x++) {
                if (haystack[i + x] != needle[x]) { found = false; break; }
            }
            if (found) return true;
        }
        return false;
    }

    function test_runnerOutput_targetIsValid() public {
        RunnerOutput memory out = _loadFixture();
        bytes memory targetBytes = bytes(out.target);

        if (out.filtered) {
            // Filtered output: target still required.
            assertTrue(targetBytes.length > 0, "filtered output must have target");
            return;
        }

        // Either native:PROS, native:PHRS, or 0x + 40 hex chars.
        // native:PROS — 11 chars: n-a-t-i-v-e-:-P-R-O-S
        //                 0 1 2 3 4 5 6 7 8 9 10
        bool isNative = targetBytes.length == 11
            && targetBytes[0] == bytes1(uint8(0x6e))  // 'n'
            && targetBytes[6] == bytes1(uint8(0x3a))  // ':'
            && targetBytes[7] == bytes1(uint8(0x50)); // 'P'
        // 0x + 40 hex chars (lowercase hex by convention)
        bool isAddress = targetBytes.length == 42
            && targetBytes[0] == bytes1(uint8(0x30))  // '0'
            && targetBytes[1] == bytes1(uint8(0x78)); // 'x'
        assertTrue(isNative || isAddress, "target must be 0x... or native:...");
    }

    function test_runnerOutput_networkIsValid() public {
        RunnerOutput memory out = _loadFixture();
        assertTrue(
            keccak256(bytes(out.network)) == keccak256(bytes("mainnet"))
                || keccak256(bytes(out.network)) == keccak256(bytes("atlantic-testnet")),
            "network must be mainnet or atlantic-testnet"
        );
    }

    function test_runnerOutput_bandIsValid() public {
        RunnerOutput memory out = _loadFixture();
        bytes memory band = bytes(out.band);
        bool ok = (
            keccak256(band) == keccak256(bytes("HEALTHY"))
            || keccak256(band) == keccak256(bytes("WATCH"))
            || keccak256(band) == keccak256(bytes("CRITICAL"))
            || keccak256(band) == keccak256(bytes("UNKNOWN"))
        );
        assertTrue(ok, "band must be HEALTHY, WATCH, CRITICAL, or UNKNOWN");
    }

    function test_runnerOutput_scoreInRange() public {
        RunnerOutput memory out = _loadFixture();
        if (out.filtered) {
            return; // score may be absent in filtered output
        }
        assertLe(out.score, 100, "score must be <= 100");
        // Note: assertGe(out.score, 0) is implicit for uint256.
    }

    function test_runnerOutput_pCrisisInRange() public {
        RunnerOutput memory out = _loadFixture();
        if (out.filtered) {
            return;
        }
        // pCrisis is 1e18-scaled; valid range is [0, 1e18].
        assertLe(out.pCrisis, 1e18, "p_crisis must be <= 1.0");
        // assertGe(pCrisis, 0) is implicit for uint256.
    }

    function test_runnerOutput_skillFieldIsCorrect() public {
        RunnerOutput memory out = _loadFixture();
        assertEq(out.skill, "liquidity-crisis-predictor", "skill must be the LCP identifier");
    }

    function test_runnerOutput_skillVersionIsSemver() public {
        RunnerOutput memory out = _loadFixture();
        bytes memory v = bytes(out.skillVersion);
        // Semver has at least MAJOR.MINOR.PATCH (e.g., "0.2.0") — 5 chars.
        assertGe(v.length, 5, "skill_version must be at least MAJOR.MINOR.PATCH");

        // Check it has two dots.
        uint256 dots = 0;
        for (uint256 i = 0; i < v.length; i++) {
            if (v[i] == bytes1(uint8(0x2e))) dots++;
        }
        assertEq(dots, 2, "skill_version must have exactly two dots");
    }

    function test_runnerOutput_timestampIsISO8601() public {
        RunnerOutput memory out = _loadFixture();
        bytes memory ts = bytes(out.timestamp);
        // YYYY-MM-DDTHH:MM:SSZ → 20 chars.
        assertEq(ts.length, 20, "timestamp must be 20 chars (ISO-8601 with Z)");
        // Verify T separator at position 10.
        assertEq(uint8(ts[10]), uint8(bytes1(uint8(0x54))), "timestamp must have T at position 10");
        // Verify Z at the end.
        assertEq(uint8(ts[19]), uint8(bytes1(uint8(0x5a))), "timestamp must end with Z");
    }

    function test_runnerOutput_bandAndScoreConsistent() public {
        RunnerOutput memory out = _loadFixture();
        if (out.filtered) {
            return;
        }

        // HEALTHY = score < 40
        // WATCH = 40 <= score < 70
        // CRITICAL = score >= 70
        if (keccak256(bytes(out.band)) == keccak256(bytes("HEALTHY"))) {
            assertLt(out.score, 40, "HEALTHY band requires score < 40");
        } else if (keccak256(bytes(out.band)) == keccak256(bytes("WATCH"))) {
            assertGe(out.score, 40, "WATCH band requires score >= 40");
            assertLt(out.score, 70, "WATCH band requires score < 70");
        } else if (keccak256(bytes(out.band)) == keccak256(bytes("CRITICAL"))) {
            assertGe(out.score, 70, "CRITICAL band requires score >= 70");
        }
    }

    function test_runnerOutput_filteredFlag() public {
        RunnerOutput memory out = _loadFixture();
        if (out.filtered) {
            // When filtered, the runner returns a slim payload
            // without score/p_crisis/drivers. Score will be 0
            // (the default for uninitialized uint), which is fine.
            // The 'band' field is still present.
            assertTrue(bytes(out.band).length > 0, "filtered output must have band");
        }
    }

    /// @notice Verify the filtered output fixture (separate from the
    ///         full output fixture). Filtered outputs have a slim
    ///         shape: just target, network, band, filtered=true, reason.
    function test_runnerOutput_filteredFixture() public {
        string memory json = vm.readFile("test/fixtures/sample-filtered.json");

        // Parsed fields (only the slim set).
        string memory target = vm.parseJsonString(json, ".target");
        string memory network = vm.parseJsonString(json, ".network");
        string memory band = vm.parseJsonString(json, ".band");
        bool filtered = _readBoolOr(json, ".filtered", false);
        string memory reason = vm.parseJsonString(json, ".reason");

        assertEq(filtered, true, "filtered fixture must have filtered=true");
        assertEq(network, "mainnet", "filtered fixture network should be mainnet");
        assertEq(band, "HEALTHY", "filtered fixture band should be HEALTHY");
        assertTrue(bytes(reason).length > 0, "filtered fixture must have a reason");
        assertTrue(bytes(target).length > 0, "filtered fixture must have a target");
    }
}