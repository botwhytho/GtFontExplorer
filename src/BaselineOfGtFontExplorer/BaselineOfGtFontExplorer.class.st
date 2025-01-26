Class {
	#name : #BaselineOfGtFontExplorer,
	#superclass : #BaselineOf,
	#category : #BaselineOfGtFontExplorer
}

{ #category : #baseline }
BaselineOfGtFontExplorer >> baseline: spec [
	<baseline>
	^ spec
		for: #common
		do: [ spec
				package: 'GtFontExplorer'
				with: [ spec postLoadDoIt: #postLoadRefactorings ] ]
]

{ #category : #'post load' }
BaselineOfGtFontExplorer >> postLoadRefactorings [
	(BlFont classVarNames includes: #AllFonts)
		ifFalse: [ (RBAddClassVariableRefactoring variable: 'AllFonts' class: BlFont) execute ]
]
