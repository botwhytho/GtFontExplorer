Extension { #name : #Character }

{ #category : #'*GtFontExplorer' }
Character >> glyphPreviewInFont: aString [
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
						aBlClickEvent modifiers = BlKeyModifiers alt
							ifTrue: [ GtClipboard clipboardText: aBlClickEvent currentTarget text asString ].
						aBlClickEvent modifiers = BlKeyModifiers new
							ifTrue: [ aBlClickEvent currentTarget phlow spawnObject: self ] ])
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
				ifNil: [ editor glamorousCodeFontAndSize ]
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
