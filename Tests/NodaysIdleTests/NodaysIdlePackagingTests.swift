import XCTest

final class NodaysIdlePackagingTests: XCTestCase {
    private var repositoryRoot: URL {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    private func textFile(_ relativePath: String) throws -> String {
        let url = repositoryRoot.appendingPathComponent(relativePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    func testReadmeUsesGitHubReleaseAndCloneLinks() throws {
        let readme = try textFile("README.md")

        XCTAssertTrue(readme.contains("https://github.com/nodaysidle/nodaysidian/releases/latest"))
        XCTAssertTrue(readme.contains("git clone https://github.com/nodaysidle/nodaysidian.git"))
        XCTAssertFalse(readme.contains(["git", "lab.com"].joined()))
        XCTAssertFalse(readme.contains(["salva", "dalba"].joined()))
    }

    func testPackageScriptCreatesExpectedBundleContract() throws {
        let script = try textFile("Scripts/package_app.sh")

        XCTAssertTrue(script.contains("APP_NAME=\"Nodaysidian\""))
        XCTAssertTrue(script.contains("EXECUTABLE_NAME=\"NodaysIdle\""))
        XCTAssertTrue(script.contains("BUNDLE_ID=\"com.nodaysidian.app\""))
        XCTAssertTrue(script.contains("MACOS_MIN_VERSION=\"15.0\""))
        XCTAssertTrue(script.contains("codesign"))
    }

    func testGeneratedReleaseArtifactsStayIgnored() throws {
        let gitignore = try textFile(".gitignore")

        XCTAssertTrue(gitignore.contains("*.app"))
        XCTAssertTrue(gitignore.contains("*.dmg"))
        XCTAssertTrue(gitignore.contains("*.tar.gz"))
        XCTAssertTrue(gitignore.contains(".build/"))
        XCTAssertTrue(gitignore.contains(".swiftpm/"))
        XCTAssertTrue(gitignore.contains("docs/codex-handoffs/"))
    }

    func testPrivacyClaimsStayLocalFirst() throws {
        let readme = try textFile("README.md")

        XCTAssertTrue(readme.contains("no account system"))
        XCTAssertTrue(readme.contains("no telemetry"))
        XCTAssertTrue(readme.contains("no network API calls for AI"))
        XCTAssertTrue(readme.contains("imported notes stay on the local Mac"))
    }
}
