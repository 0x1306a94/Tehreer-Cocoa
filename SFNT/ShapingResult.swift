//
// Copyright (C) 2019 Muhammad Tayyab Akram
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import CoreGraphics

/// A `ShapingResult` object is a container for the results of text shaping. It is generated by a
/// `ShapingEngine` object to provide the information related to characters, their glyphs, offsets,
/// and advances.
public class ShapingResult {
    let sfAlbum: SFAlbumRef

    private var sizeByEm: CGFloat = 0.0
    private var stringRange: Range<String.Index>!
    private var codeUnitCount: Int = 0

    init() {
        sfAlbum = SFAlbumCreate()
    }

    deinit {
        SFAlbumRelease(sfAlbum)
    }

    /// A boolean value that indicates whether the shaped text segment flows backward.
    public private(set) var isBackward: Bool = false

    public var startIndex: String.Index {
        return stringRange.lowerBound
    }

    public var endIndex: String.Index {
        return stringRange.upperBound
    }

    var glyphCount: Int {
        return Int(SFAlbumGetGlyphCount(sfAlbum))
    }

    /// The collection of glyph IDs.
    public var glyphIDs: PrimitiveCollection<UInt16> {
        let pointer = SFAlbumGetGlyphIDsPtr(sfAlbum)
        let collection = OwnedCollection(owner: self, pointer: pointer, size: glyphCount)

        return PrimitiveCollection(collection)
    }

    /// The collection of glyph offsets.
    public var glyphOffsets: PrimitiveCollection<CGPoint> {
        let pointer = SFAlbumGetGlyphOffsetsPtr(sfAlbum)
        let collection = OwnedScaleCollection(owner: self,
                                              pointer: pointer,
                                              size: glyphCount,
                                              scale: sizeByEm)

        return PrimitiveCollection(collection)
    }

    /// The collection of glyph advances.
    public var glyphAdvances: PrimitiveCollection<CGFloat> {
        let pointer = SFAlbumGetGlyphAdvancesPtr(sfAlbum)
        let collection = OwnedScaleCollection(owner: self,
                                              pointer: pointer,
                                              size: glyphCount,
                                              scale: sizeByEm)

        return PrimitiveCollection(collection)
    }

    /// A collection of indexes, mapping each shaped UTF-16 code unit in source string to
    /// corresponding glyph.
    ///
    /// The map is produced according to following rules.
    ///
    /// 1. If a single code unit translates into multiple glyphs, then it maps to the first glyph in
    ///    the sequence.
    /// 2. If multiple code units form a group, such as a grapheme, which in turn translates into
    ///    into multiple glyphs, then each character maps to the first glyph in the sequence.
    /// 3. If nonconsecutive code units translate to a single glyph or ligature, then each
    ///    participating code unit, and all in-between characters, map to this glyph or ligature.
    public var clusterMap: PrimitiveCollection<Int> {
        let pointer = SFAlbumGetCodeunitToGlyphMapPtr(sfAlbum)
        let collection = OwnedCollection(owner: self, pointer: pointer, size: codeUnitCount)

        return PrimitiveCollection(collection.map({ Int($0) }))
    }

    public func caretEdges(with caretStops: [Bool]?) -> PrimitiveCollection<CGFloat> {
        if let caretStops = caretStops {
            precondition(caretStops.count >= codeUnitCount)
        }

        let edgeCount = codeUnitCount + 1
        let unsafeEdges = UnsafeMutablePointer<SFFloat>.allocate(capacity: edgeCount)
        defer { unsafeEdges.deallocate() }

        let loaded = caretStops?.withUnsafeBufferPointer { (buffer) -> Bool? in
            guard let baseAddress = buffer.baseAddress else {
                return nil
            }

            let unsafeStops = UnsafeMutablePointer<SFBoolean>(OpaquePointer(baseAddress))
            SFAlbumGetCaretEdges(sfAlbum, unsafeStops, SFFloat(sizeByEm), unsafeEdges)

            return true
        }

        if loaded == nil {
            SFAlbumGetCaretEdges(sfAlbum, nil, SFFloat(sizeByEm), unsafeEdges)
        }

        let edgesBuffer = UnsafeBufferPointer(start: unsafeEdges, count: edgeCount)
        let edgesArray = edgesBuffer.map { CGFloat($0) }

        return PrimitiveCollection(edgesArray, range: 0 ..< edgeCount)
    }

    func setAdditionalInfo(sizeByEm: CGFloat, isBackward: Bool, stringRange: Range<String.Index>, codeUnitCount: Int) {
        self.sizeByEm = sizeByEm
        self.isBackward = isBackward
        self.stringRange = stringRange
        self.codeUnitCount = codeUnitCount
    }
}

