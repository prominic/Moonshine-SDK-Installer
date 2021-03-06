package actionScripts.valueObjects;

import feathers.data.ArrayCollection;

extern class PackageVO
{
	public var title:String;
	public var description:String;
	public var imagePath:String;
	public var isIntegrated:Bool;
	
	@:flash.property
	public var dependencyTypes(default, default):ArrayCollection<ComponentVO>;
}