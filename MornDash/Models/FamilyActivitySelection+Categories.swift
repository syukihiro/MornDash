import FamilyControls

extension FamilyActivitySelection {
    /// Clears category tokens; apps and web domains are unchanged.
    func clearingCategories() -> FamilyActivitySelection {
        var copy = self
        copy.categoryTokens = []
        return copy
    }
}
