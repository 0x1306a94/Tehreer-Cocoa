//
// Copyright (C) 2019-2021 Muhammad Tayyab Akram
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
import FreeType

class GlyphKey: Hashable {
    var typeface: Typeface! = nil
    var pixelWidth: FT_F26Dot6 = 0  // 26.6 fixed-point value.
    var pixelHeight: FT_F26Dot6 = 0 // 26.6 fixed-point value.
    var skewX: FT_Fixed = 0         // 16.16 fixed-point value.

    fileprivate init() { }

    func copy() -> GlyphKey {
        fatalError()
    }

    fileprivate func set(from key: GlyphKey) {
        typeface = key.typeface
        pixelWidth = key.pixelWidth
        pixelHeight = key.pixelHeight
        skewX = key.skewX
    }

    fileprivate func equals(_ key: GlyphKey) -> Bool {
        return typeface === key.typeface
            && pixelWidth == key.pixelWidth
            && pixelHeight == key.pixelHeight
            && skewX == key.skewX
    }

    static func ==(lhs: GlyphKey, rhs: GlyphKey) -> Bool {
        return lhs.equals(rhs)
    }

    func hash(into hasher: inout Hasher) {
        if typeface != nil {
            hasher.combine(ObjectIdentifier(typeface))
        }

        hasher.combine(pixelWidth)
        hasher.combine(pixelHeight)
        hasher.combine(skewX)
    }
}

extension GlyphKey {
    final class Data: GlyphKey {
        override init() { }

        override func copy() -> Data {
            let key = Data()
            key.set(from: self)

            return key
        }

        override func equals(_ key: GlyphKey) -> Bool {
            if self === key {
                return true
            }
            guard let key = key as? Data else {
                return false
            }

            return super.equals(key)
        }
    }
}
