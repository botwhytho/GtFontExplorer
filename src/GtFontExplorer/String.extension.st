Extension { #name : #String }

{ #category : #'*GtFontExplorer' }
String >> gtPreviewInFontFor: aView context: aContext [
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
		fontSize: 20;
		text: [ self ];
		actionButtonLabel: 'Copy Styled Text'
			tooltip: 'Copies styled text creation code'
			action: [ :aBrButton :aBrTab :aBrButtonModel :aBlClickEvent | 
				| editor |
				editor := aBrTab viewContentElement childNamed: #editor.
				aBlClickEvent consumed: true.
				GtClipboard
					clipboardText: $' asString , editor text asString , $' asString , ' asRopedText fontName: '
							, $' asString , font familyName , $' asString ]
]
