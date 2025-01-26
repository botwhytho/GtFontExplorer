Extension { #name : #UnicodeCharacterData }

{ #category : #'*GtFontExplorer' }
UnicodeCharacterData class >> groupedByCategory [
	^ ((self database groupedBy: #generalCategory) associations
		sorted: [ :each | each value size ] descending) asOrderedDictionary
]
