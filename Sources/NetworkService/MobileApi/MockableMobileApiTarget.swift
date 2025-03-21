import Foundation

public protocol MockableMobileApiTarget: MobileApiTargetType {
    var isMockEnabled: Bool { get }
    
    func getMockFileName() -> String?
}

extension MockableMobileApiTarget {
    var sampleData: Data { getSampleData() }

    private func getSampleData() -> Data {
        guard let mockFileName = getMockFileName() else {
            let log = "💽🆓 Для запроса \(path) моковые данные не используются."
            Log.mockableMobileApiTarget.debug(logEntry: .text(log))
            return Data()
        }

        return getSampleDataFromFileWithName(mockFileName)
    }
}

public protocol MockablePaginationMobileApiTarget: MockableMobileApiTarget {
    var pageIndexParameterName: String { get }
    var pageSizeParameterName: String { get }
}

extension MockablePaginationMobileApiTarget {
    var sampleData: Data { getSampleData() }

    private func getSampleData() -> Data {
        guard var mockFileName = getMockFileName() else {
            let log = "💽🆓 Для запроса \(path) моковые данные не используются."
            Log.mockableMobileApiTarget.debug(logEntry: .text(log))
            return Data()
        }

        if
            let pageIndex = parameters[pageIndexParameterName],
            let pageSize = parameters[pageSizeParameterName]
        {
            mockFileName = "\(mockFileName)&PI=\(pageIndex)&PS=\(pageSize)"
        }

        return getSampleDataFromFileWithName(mockFileName)
    }
}

fileprivate extension MockableMobileApiTarget {
    func getSampleDataFromFileWithName(_ mockFileName: String) -> Data {
        let logStart = "Для запроса \(path) моковые данные"
        let mockExtension = "json"

        guard let mockFileUrl = Bundle.main.url(forResource: mockFileName, withExtension: mockExtension) else {
            let log = "💽🚨 \(logStart) \(mockFileName).\(mockExtension) не найдены."
            Log.mockableMobileApiTarget.error(logEntry: .text(log))
            return Data()
        }

        do {
            let data = try Data(contentsOf: mockFileUrl)
            let log = "💽✅ \(logStart) успешно прочитаны по URL: \(mockFileUrl)."
            Log.mockableMobileApiTarget.debug(logEntry: .text(log))
            return data
        } catch {
            let log =
            "💽🚨\n\(logStart) из файла \(mockFileName).\(mockExtension) невозможно прочитать.\nОшибка: \(error)"
            Log.mockableMobileApiTarget.error(logEntry: .text(log))
            return Data()
        }
    }
}
