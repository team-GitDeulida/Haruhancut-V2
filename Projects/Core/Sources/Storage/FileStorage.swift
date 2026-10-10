//
//  FileStorage.swift
//  Core
//
//  Created by 김동현 on 10/10/26.
//

import Foundation

/*
 [사용법]
 let storage = FileStorage(location: .appGroup("group.com.example"))

 // 공통 CRUD (StorageType). 중간 폴더가 없으면 만듭니다
 try storage?.write(data, to: "Photos/family/2026-10-10/photo.jpg")
 let data = storage?.read("Photos/family/2026-10-10/photo.jpg")
 storage?.remove("Photos/family/2026-10-10") // 파일과 폴더 모두

 // 파일 저장소에만 있는 기능 (FileStorage 익스텐션)
 let names = storage?.contentsOfDirectory("Photos/family/2026-10-10")
 let hasFolder = storage?.exists("Photos/family") ?? false
 */

/// 기준 폴더 아래 파일에 저장하는 저장소입니다.
///
/// `baseURL`·`fileManager`만 제공하면 공통 CRUD(`StorageType`)는 아래 익스텐션의 기본 구현을 씁니다.
/// 키는 기준 폴더에서 시작하는 상대 경로입니다. (예: `Photos/family/2026-10-10/photo.jpg`)
public protocol FileStorageType: StorageType {
    /// 상대 경로의 기준이 되는 폴더입니다.
    var baseURL: URL { get }
    var fileManager: FileManager { get }
}

public extension FileStorageType {
    /// 파일을 원자적으로 저장합니다. 중간 폴더가 없으면 만듭니다.
    func write(_ data: Data, to path: String) throws {
        let fileURL = url(for: path)
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        // 임시 파일에 쓴 뒤 교체해 쓰는 도중 파일이 깨지지 않게 합니다.
        try data.write(to: fileURL, options: .atomic)
    }

    /// 파일을 읽습니다. 파일이 없으면 `nil`입니다.
    func read(_ path: String) -> Data? {
        try? Data(contentsOf: url(for: path))
    }

    /// 파일이나 폴더를 지웁니다. 없으면 아무 일도 하지 않습니다.
    func remove(_ path: String) {
        try? fileManager.removeItem(at: url(for: path))
    }
}

extension FileStorageType {
    /// 상대 경로를 기준 폴더 아래의 URL로 바꿉니다.
    func url(for path: String) -> URL {
        path
            .split(separator: "/")
            .reduce(baseURL) { url, component in
                url.appendingPathComponent(String(component))
            }
    }
}

/// `FileManager`로 App Group·Documents·Caches 폴더에 저장하는 파일 저장소입니다.
public final class FileStorage: FileStorageType {

    /// 기준 폴더의 위치입니다.
    public enum Location {
        /// 앱과 익스텐션이 공유하는 App Group 컨테이너입니다.
        case appGroup(String)
        /// 사용자 데이터를 두는 Documents 폴더입니다.
        case documents
        /// 지워져도 다시 만들 수 있는 데이터를 두는 Caches 폴더입니다.
        case caches
    }

    public let baseURL: URL
    public let fileManager: FileManager

    /// 지정한 기준 폴더를 쓰는 저장소를 만듭니다. 테스트에서는 임시 폴더를 넘깁니다.
    ///
    /// - Parameters:
    ///   - baseURL: 상대 경로의 기준이 되는 폴더.
    ///   - fileManager: 파일 작업에 쓰는 `FileManager`.
    public init(
        baseURL: URL,
        fileManager: FileManager = .default
    ) {
        self.baseURL = baseURL
        self.fileManager = fileManager
    }

    /// 저장 위치에 맞는 저장소를 만듭니다.
    ///
    /// - Parameters:
    ///   - location: 기준 폴더의 위치.
    ///   - fileManager: 파일 작업에 쓰는 `FileManager`.
    /// - Returns: 기준 폴더를 찾지 못하면 `nil`. App Group 권한이 없는 타깃이 여기에 해당합니다.
    public convenience init?(
        location: Location,
        fileManager: FileManager = .default
    ) {
        let baseURL: URL?
        switch location {
        case .appGroup(let identifier):
            baseURL = fileManager.containerURL(
                forSecurityApplicationGroupIdentifier: identifier
            )
        case .documents:
            baseURL = fileManager
                .urls(for: .documentDirectory, in: .userDomainMask)
                .first
        case .caches:
            baseURL = fileManager
                .urls(for: .cachesDirectory, in: .userDomainMask)
                .first
        }

        guard let baseURL else { return nil }
        self.init(baseURL: baseURL, fileManager: fileManager)
    }
}

/// 파일 저장소에만 필요한 기능입니다.
public extension FileStorage {
    /// 폴더 안 항목의 이름입니다. 숨김 파일은 빼고, 폴더가 없으면 빈 배열입니다.
    func contentsOfDirectory(_ path: String) -> [String] {
        let urls = try? fileManager.contentsOfDirectory(
            at: url(for: path),
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        return urls?.map(\.lastPathComponent) ?? []
    }

    /// 파일이나 폴더가 있는지 확인합니다.
    func exists(_ path: String) -> Bool {
        fileManager.fileExists(atPath: url(for: path).path)
    }
}
