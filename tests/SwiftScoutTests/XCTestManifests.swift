import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AuthTests.allTests),
        testCase(UserTests.allTests),
        testCase(TicketTests.allTests),
        testCase(IntegrationTests.allTests)
    ]
}
#endif 