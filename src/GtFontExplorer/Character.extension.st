Extension { #name : #Character }

{ #category : #'*GtFontExplorer' }
Character >> glyphPreviewInFont: aString spawnFont: aBoolean [
	^ BrFrame new
		size: 50 @ 50;
		border: (BlBorder paint: Color veryLightGray width: 1);
		aptitude: BrGlamorousFocusableShadowAptitude;
		addChild: (BrEditor new
				fitContent;
				constraintsDo: [ :c | 
					c frame horizontal alignCenter.
					c frame vertical alignCenter ];
				beReadOnlyWithoutSelection;
				aptitude: (BrEditorAptitude new
						fontName: aString;
						fontSize: 30);
				text: self asString asRopedText;
				when: BlClickEvent
					do: [ :aBlClickEvent | 
						aBlClickEvent consumed: true.
						aBoolean
							ifTrue: [ aBlClickEvent currentTarget phlow
									spawnObject: (BlFont new familyName: aString) ]
							ifFalse: [ aBlClickEvent modifiers = BlKeyModifiers alt
									ifTrue: [ GtClipboard clipboardText: aBlClickEvent currentTarget text asString ].
								aBlClickEvent modifiers = BlKeyModifiers new
									ifTrue: [ aBlClickEvent currentTarget phlow spawnObject: self ] ] ])
]

{ #category : #'*GtFontExplorer' }
Character >> gtLargePreviewFor: aView context: aContext [
	<gtView>
	| font |
	aContext navigation previousContext object
		in: [ :anObject | font := (anObject isKindOf: BlFont) ifTrue: [ anObject ] ifFalse: [ nil ] ].
	^ aView textEditor
		title: 'Large Preview';
		priority: 15;
		in: [ :editor | 
			font
				ifNil: [ editor glamorousCodeFont ]
				ifNotNil: [ editor fontName: font familyName ].
			editor ];
		fontSize: 500;
		text: [ self ]
]

{ #category : #'*GtFontExplorer' }
Character >> gtPreviewInFontFor: aView context: aContext [
	<gtView>
	| font |
	aContext navigation previousContext object
		in: [ :anObject | 
			(anObject isKindOf: BlFont)
				ifTrue: [ font := anObject ]
				ifFalse: [ ^ aView empty ] ].
	^ aView textEditor
		title: 'Font Preview';
		priority: 5;
		fontName: font familyName;
		fontSize: 30;
		text: [ self ]
]

{ #category : #'*GtFontExplorer' }
Character >> gtSupportedFontsFor: aView [
	<gtView>
	| allFonts |
	allFonts := (self allSuportedFontsForCharacter
			collect: [ :each | 
				| split |
				split := each splitOn: '|'.
				split first ifEmpty: [ split second ] ]) sorted.
	^ aView explicit
		title: 'Supported Fonts';
		priority: 50;
		stencil: [ | aFontStream glyphElemenDimension listElement |
			aFontStream := allFonts asAsyncStream.
			glyphElemenDimension := 50.
			listElement := BrSimpleList new matchParent.
			listElement
				enqueueTask: [ | glyphsPerRow |
					glyphsPerRow := listElement width // glyphElemenDimension.
					aFontStream := aFontStream chunks: glyphsPerRow.
					aFontStream := (aFontStream
							collect: [ :someFonts | 
								[ | grid |
								grid := BrHorizontalGrid new
										height: glyphElemenDimension;
										hFitContent;
										columnCount: glyphsPerRow.
								grid
									addChildren: (someFonts collect: [ :aFont | self glyphPreviewInFont: aFont spawnFont: true ]).
								grid ] asAsyncFuture asAsyncStream ]) asAsyncStream flatten.
					aFontStream := aFontStream terminatable.
					listElement userData at: #stream put: aFontStream.
					listElement
						itemsProvider: (BrStreamItemsProvider new
								preloadAmount: 50;
								stream: aFontStream;
								yourself);
						stencil: #yourself ] asBlTask.
			listElement ];
		actionButtonIcon: BrGlamorousVectorIcons stop
			tooltip: 'Stop loading more fonts'
			action: [ :aButton :aBrTab :aBrToggleActivatedEvent | (aBrTab viewContentElement userData at: #stream) terminate ];
		actionButtonIcon: BrGlamorousVectorIcons refresh
			tooltip: 'Reload view'
			action: [ :aBrButton :aBrTab :aBrButtonModel :aBlClickEvent | 
				aBlClickEvent consumed: true.
				(aBrTab viewContentElement userData at: #stream) terminate.
				(self gtSupportedFontsFor: GtPhlowEmptyView new)
					updateContent: aBrTab viewContentElement ]
]
