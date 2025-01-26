Class {
	#name : #BaselineOfGtFontExplorer,
	#superclass : #BaselineOf,
	#category : #BaselineOfGtFontExplorer
}

{ #category : #baseline }
BaselineOfGtFontExplorer >> baseline: spec [
	<baseline>
		^ spec for: #common do: [
			spec package: 'GtFontExplorer'
		]
]
