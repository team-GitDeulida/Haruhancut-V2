//
//  Codable+.swift
//  Core
//
//  Created by 김동현 on 1/15/26.
//

import Foundation

extension Encodable {
    public func toDictionary() -> [String: Any]? {
        do {
            let data = try JSONEncoder().encode(self)
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            return jsonObject as? [String: Any]
        } catch {
            print("❌ toDictionary 변환 실패: \(error)")
            return nil
        }
    }
}

extension Decodable {
    public static func fromDictionary(_ dict: [String: Any]) -> Self? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dict)
            let decodedObject = try JSONDecoder().decode(Self.self, from: data)
            return decodedObject
        } catch {
            print("❌ fromDictionary 변환 실패: \(error)")
            return nil
        }
    }
}
