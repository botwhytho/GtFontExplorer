Extension { #name : #BlFont }

{ #category : #'*GtFontExplorer' }
BlFont class >> allFontsSorted [
	| allFonts |
	self flag: #TODO. "Compile class sot at class/baseline startup"
	^ AllFonts
		ifNil: [ allFonts := self fontsInSystem , self fontsInGtDirectory
					collect: [ :each | each splitOn: '|' ].
			AllFonts := allFonts
					sorted: [ :a :b | 
						| aName bName |
						aName := a first ifEmpty: [ a third ].
						bName := b first ifEmpty: [ b third ].
						aName = bName ifTrue: [ a second < b second ] ifFalse: [ aName < bName ] ] ]
]

{ #category : #'*GtFontExplorer' }
BlFont >> codePointsDefinedInFont [
	| charsets codepoints font output |
	font := self class allFontsSorted
			detect: [ :each | (each first ifEmpty: [ each third ]) = self familyName ]
			ifFound: #second
			ifNone: [ self familyName ].
	output := OSPlatform current isLinux
			ifTrue: [ (GtExternalProcessBuilder new
					command: 'fc-query';
					args: {'--format=%{charset}\n'.
							font};
					pipeStdout;
					pipeStderr;
					spawn) waitWithOutput stdout lines ]
			ifFalse: [ #() ].
	charsets := output
			ifNotEmpty: [ :notEmpty | notEmpty flatCollect: [ :each | each splitOn: ' ' ] ].
	codepoints := (charsets
			collect: [ :each | 
				| range |
				range := each splitOn: '-'.
				range size = 1
					ifTrue: [ {Number readFrom: range first base: 16} ]
					ifFalse: [ ((Number readFrom: range first base: 16)
							to: (Number readFrom: range second base: 16)) asArray ] ])
			flatCollectAsSet: #yourself.
	^ (UnicodeCharacterData database keys intersection: codepoints) asArray
		sorted: #yourself ascending
]

{ #category : #'*GtFontExplorer' }
BlFont class >> fontsInGtDirectory [
	^ OSPlatform current isLinux
		ifTrue: [ self getAllGtFonts ]
		ifFalse: [ #() ]
]

{ #category : #'*GtFontExplorer' }
BlFont class >> fontsInSystem [
	^ OSPlatform current isLinux
		ifTrue: [ self getAllSystemFonts ]
		ifFalse: [ #() ]
]

{ #category : #'*GtFontExplorer' }
BlFont class >> getAllGtFonts [
	^ (GtExternalProcessBuilder new
		command: 'fc-scan';
		args: {'--format=%{fullname}|%{file}|%{family}|%{charset}\n'.
				'.' asFileReference asAbsolute pathString};
		pipeStdout;
		pipeStderr;
		spawn) waitWithOutput stdout lines
]

{ #category : #'*GtFontExplorer' }
BlFont class >> getAllSystemFonts [
	^ (GtExternalProcessBuilder new
		command: 'fc-list';
		args: {'--format=%{fullname}|%{file}|%{family}|%{charset}\n'};
		pipeStdout;
		pipeStderr;
		spawn) waitWithOutput stdout lines
]

{ #category : #'*GtFontExplorer' }
BlFont >> gtDefinedCharactersFor: aView [
	<gtView>
	^ aView explicit
		title: 'Defined Characters';
		stencil: [ | aCharacterStream ascendingCodePoints glyphElemenDimension listElement |
			ascendingCodePoints := self codePointsDefinedInFont.
			aCharacterStream := ascendingCodePoints asAsyncStream.
			glyphElemenDimension := 50.
			listElement := BrSimpleList new matchParent.
			listElement
				enqueueTask: [ | glyphsPerRow |
					glyphsPerRow := listElement width // glyphElemenDimension.
					aCharacterStream := aCharacterStream chunks: glyphsPerRow.
					aCharacterStream := (aCharacterStream
							collect: [ :decimalCodePoints | 
								[ | grid |
								grid := BrHorizontalGrid new
										height: glyphElemenDimension;
										hFitContent;
										columnCount: glyphsPerRow.
								grid
									addChildren: (decimalCodePoints
											collect: [ :aDecimalCodePoint | 
												(UnicodeCharacterData database at: aDecimalCodePoint) character
													glyphPreviewInFont: self familyName spawnFont: false ]).
								grid ] asAsyncFuture asAsyncStream ]) asAsyncStream flatten.
					listElement
						itemsProvider: (BrStreamItemsProvider new
								preloadAmount: 50;
								stream: aCharacterStream;
								yourself);
						stencil: #yourself ] asBlTask.
			listElement ]
]

{ #category : #'*GtFontExplorer' }
BlFont >> gtDetailedInfoFor: aView [
	"<gtView>"
	self flag: #TODO. "Do we need this? Need to clean this up more and take into account fonts in GT directory and how to get to proper font file"
	^ ((OSPlatform current isLinux
		ifTrue: [ | details output |
			output := (GtExternalProcessBuilder new
					command: 'fc-list';
					arguments: {'-v'.
							self familyName};
					pipeStdout;
					pipeStderr;
					spawn) waitWithOutput stdout lines.
			details := output allButFirst
					select: [ :each | each includesSubstring: ':' ]
					thenCollect: [ :each | 
						((each splitOnFirst: $:) collect: #trimBoth)
							in: [ :fields | {fields first -> fields second} ] ].
			{'Info' -> output first} , details flatten ]
		ifFalse: [ {'Info' -> 'Not available in this OS'} ]) asOrderedDictionary
		gtItemsFor: aView)
		title: 'Detailed Info';
		priority: 8
]

{ #category : #'*GtFontExplorer' }
BlFont class >> gtEmojisFor: aView [
	<gtClassView>
	<gtView>
	^ aView explicit
		title: 'Emojis';
		priority: 10;
		stencil: [ | aCharacterStream ascendingCodePoints emojiIndices glyphElemenDimension listElement smileyIndex |
			smileyIndex := Number readFrom: '1f600' base: 16.
			ascendingCodePoints := UnicodeCharacterData database keys sorted.
			emojiIndices := {smileyIndex}
					, (ascendingCodePoints splitOn: smileyIndex) second.
			aCharacterStream := emojiIndices asAsyncStream.
			glyphElemenDimension := 50.
			listElement := BrSimpleList new matchParent.
			listElement
				enqueueTask: [ | glyphsPerRow |
					glyphsPerRow := listElement width // glyphElemenDimension.
					aCharacterStream := aCharacterStream chunks: glyphsPerRow.	" 50 rows at once"
					aCharacterStream := (aCharacterStream
							collect: [ :decimalCodePoints | 
								[ | grid |
								grid := BrHorizontalGrid new
										height: glyphElemenDimension;
										hFitContent;
										columnCount: glyphsPerRow.
								grid
									addChildren: (decimalCodePoints
											collect: [ :aDecimalCodePoint | 
												(UnicodeCharacterData database at: aDecimalCodePoint) character
													glyphPreviewInFont: 'Source Sans Pro' spawnFont: false ]).
								grid ] asAsyncFuture asAsyncStream ]) asAsyncStream flatten.
					listElement
						itemsProvider: (BrStreamItemsProvider new
								preloadAmount: 50;
								stream: aCharacterStream;
								yourself);
						stencil: #yourself ] asBlTask.
			listElement ]
]

{ #category : #'*GtFontExplorer' }
BlFont class >> gtFontsInSystemFor: aView [
	<gtClassView>
	<gtView>
	| fonts |
	fonts := self allFontsSorted.
	^ aView columnedList
		title: 'Fonts In System (' , fonts size asString , ')';
		priority: 1;
		items: fonts;
		column: 'Font Name' text: [ :each | each first ifEmpty: [ each third ] ];
		column: 'Defined Characters'
			text: [ :each | (BlFont new familyName: (each first ifEmpty: [ each third ])) codePointsDefinedInFont size ];
		column: 'File'
			text: #second
			spawn: [ :each | each second asFileReference ];
		send: [ :each | self new familyName: each first ];
		actionStencil: [ :aButton :aBrTab | 
			GtSpotterDropdownButtonStencil new
				tooltip: 'Search Fonts';
				label: 'Fonts';
				hidePreview;
				object: fonts;
				objectActOn: [ :anActOnEvent :anItem :theButton | 
						| target |
						target := anActOnEvent objectToSend.
						(target isKindOf: OrderedCollection) 
							ifTrue: [ 
								| columnedList |
						
								columnedList := theButton phlow viewContent 
									allChildrenBreadthFirstDetect: [ :child | 
										child isKindOf:  BrColumnedList ] 
									ifFound: [ :child | child ].
								columnedList scrollToItem: target.
								columnedList selectOne: (columnedList items indexOf: target).
								
								anActOnEvent beActed ] ];
				create ]
]

{ #category : #'*GtFontExplorer' }
BlFont >> gtInfoFor: aView [
	<gtView>

	^ ({
		#'Family name' -> self familyName.
		#Size -> self fontSize.
		#Slant -> (('{1} ({2})') format: { self fontSlant name . self fontSlant value }).
		#Stretch -> (('{1} ({2})') format: { self fontStretch name . self fontStretch value }).
		#Weight -> (('{1} ({2})') format: { self fontWeight name . self fontWeight value }).
	 } asOrderedDictionary gtItemsFor: aView)
			title: 'Info';
			priority: 7
]

{ #category : #'*GtFontExplorer' }
BlFont >> gtPreviewFor: aView [
	<gtView>
	
	^ aView text
		title: 'Preview';
		priority: 5;
		text: [
			| aText |
			aText := 'ABCDEFGHIJKLM
NOPQRSTUVWXYZ
abcdefghijklm
nopqrstuvwxyz
1234567890' asRopedText.
			(self fontSize: 80) applyOnText: aText.
			aText ]
]

{ #category : #'*GtFontExplorer' }
BlFont >> gtSpotterUnicodeCharacterDatabaseFor: aSearch [
	<gtSearch>
	^ aSearch list
		priority: 10;
		title: 'Unicode character database';
		items: [ UnicodeCharacterData database values sorted ];
		itemName: [ :each | each printString ];
		send: [ :aRawObject :aStep :thisSearch | aRawObject character ];
		filterBySubstring
]

{ #category : #'*GtFontExplorer' }
BlFont >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPutAll: ' (';
		nextPutAll: self familyName;
		nextPutAll: ' [';
		nextPutAll: self codePointsDefinedInFont size asString;
		nextPutAll: ' glyphs])'
]
