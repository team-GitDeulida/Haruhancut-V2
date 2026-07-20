import Foundation

/// A section and the item identifiers it contains.
public struct CollectionViewSection<SectionIdentifier: Hashable, ItemIdentifier: Hashable> {
    public let id: SectionIdentifier
    public var items: [ItemIdentifier]

    public init(
        id: SectionIdentifier,
        items: [ItemIdentifier]
    ) {
        self.id = id
        self.items = items
    }
}
