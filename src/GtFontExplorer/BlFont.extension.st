Extension { #name : #BlFont }

{ #category : #'*GtFontExplorer' }
BlFont class >> allFontsSorted [
	^ (self fontsInSystem , self fontsInGtDirectory
		collect: [ :each | each splitOn: '|' ])
		sorted: [ :a :b | 
			a first
				ifEmpty: [ b first ifEmpty: [ a second < b second ] ifNotEmpty: [ false ] ]
				ifNotEmpty: [ a first < b first ] ]
]

{ #category : #'*GtFontExplorer' }
BlFont >> codePointsDefinedInFont [

"^ OSPlatform current isLinux
		ifTrue: [ (GtExternalProcessBuilder new
				command: 'fc-query';
				args: {'--format=''%{charset}\n'''. self familyName};
				pipeStdout;
				pipeStderr;
				spawn) waitWithOutput stdout lines
				collect: [ :each | 
					((each splitOn: $:) collect: #trimBoth)
						in: [ :fields | 
							{'file' -> fields first.
								'name' -> fields second.
								'style' -> fields third} asDictionary ] ] ]
		ifFalse: [ #() ]"
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
		args: {'--format=%{fullname}|%{file}\n'.
				'.' asFileReference asAbsolute pathString};
		pipeStdout;
		pipeStderr;
		spawn) waitWithOutput stdout lines
]

{ #category : #'*GtFontExplorer' }
BlFont class >> getAllSystemFonts [
	^ (GtExternalProcessBuilder new
		command: 'fc-list';
		args: {'--format=%{fullname}|%{file}\n'};
		pipeStdout;
		pipeStderr;
		spawn) waitWithOutput stdout lines
]

{ #category : #'*GtFontExplorer' }
BlFont >> gtDetailedInfoFor: aView [
	<gtView>
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
BlFont >> gtEmojisFor: aView [
	<gtView>
	^ aView explicit
		title: 'Emojis';
		stencil: [ | aCharacterStream ascendingCodePoints emojiIndices glyphElemenDimension listElement smileyIndex |
			smileyIndex := Number readFrom: '1f600' base: 16.
			ascendingCodePoints := UnicodeCharacterData database keys sorted.
			emojiIndices := {smileyIndex}
					, (ascendingCodePoints splitOn: smileyIndex) second.
			aCharacterStream := emojiIndices asAsyncStream.	"first: 1500"
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
													glyphPreviewInFont: self familyName ]).
								grid ] asAsyncFuture asAsyncStream ]) asAsyncStream flatten.
					listElement
						itemsProvider: (BrStreamItemsProvider new
								preloadAmount: 50;
								stream: aCharacterStream;
								yourself);
						stencil: #yourself;
						when: BrItemsProviderDoneEvent do: [ :anEvent | self inform: 'All Glyphs have been fetched' ] ]
						asBlTask.
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
		column: 'Font Name' text: #first;
		column: 'Supported Glyphs'
			stencil: [ :each | 
				self flag: #TODO.	"Async fetch"
				BlTextElement text: 42 asRopedText ];
		column: 'File'
			text: #second
			spawn: [ :each | each second asFileReference ];
		send: [ :each | self new familyName: each first ];
		actionStencil: [ :aButton :aBrTab | 
			GtSpotterDropdownButtonStencil new
				tooltip: 'Search Fonts';
				label: 'Fonts';
				hidePreview;
				valuable: [ fonts collect: [ :each | each first -> each second ] ];
				actOn: [ :anActOnEvent :anItem :aBrButton | 
					anActOnEvent beActed.
					aBrButton phlow spawnObject: (BlFont new familyName: anItem key).
					aBrButton fireEvent: BrDropdownHideWish new ];
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
BlFont >> gtLettersFor: aView [
	<gtView>
	^ aView explicit
		title: 'Glyphs Supported';
		stencil: [ | aCharacterStream ascendingCodePoints  glyphElemenDimension listElement  |
			ascendingCodePoints := self codePointsDefinedInFont.
			aCharacterStream := ascendingCodePoints asAsyncStream.
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
													glyphPreviewInFont: self familyName ]).
								grid ] asAsyncFuture asAsyncStream ]) asAsyncStream flatten.
					listElement
						itemsProvider: (BrStreamItemsProvider new
								preloadAmount: 50;
								stream: aCharacterStream;
								yourself);
						stencil: #yourself;
						when: BrItemsProviderDoneEvent do: [ :anEvent | self inform: 'All Glyphs have been fetched' ] ]
						asBlTask.
			listElement ]
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
		send: [ :aRawObject :aStep :thisSearch | 
			GtPhlowEmptyView new textEditor
				title: 'Preview';
				priority: 10;
				fontName: self familyName;
				fontSize: 64;
				text: [ aRawObject character ] ];
		filterBySubstring
]
