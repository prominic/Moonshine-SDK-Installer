package actionScripts.interfaces
{
	public interface IHelperMoonshineBridge
	{
		function isDefaultSDKPresent():Boolean;
		function isFlexSDKAvailable():Object;
		function isFlexHarmanSDKAvailable():Object;
		function isFlexJSSDKAvailable():Object;
		function isRoyaleSDKAvailable():Object;
		function isFeathersSDKAvailable():Object;
		function isJavaPresent():Boolean;
		function isJava8Present():Boolean;
		function isAntPresent():Boolean;
		function isMavenPresent():Boolean;
		function isGradlePresent():Boolean;
		function isGrailsPresent():Boolean;
		function isSVNPresent():Boolean;
		function isGitPresent():Boolean;
		function isNodeJsPresent():Boolean;
		function isNotesDominoPresent():Boolean;
		function runOrDownloadSDKInstaller():void;

		function get playerglobalExists():Boolean;
		function set playerglobalExists(value:Boolean):void;
		function get javaVersionForTypeahead():String;
		function get javaVersionInJava8Path():String;
	}
}