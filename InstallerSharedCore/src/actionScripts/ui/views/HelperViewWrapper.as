package actionScripts.ui.views
{
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import actionScripts.interfaces.IHelperMoonshineBridge;
	import actionScripts.locator.HelperModel;
	import actionScripts.managers.InstallerItemsManager;
	import actionScripts.managers.StartupHelper;
	import actionScripts.ui.FeathersUIWrapper;
	import actionScripts.utils.EnvironmentUtils;
	import actionScripts.valueObjects.ComponentTypes;
	import actionScripts.valueObjects.ComponentVO;
	import actionScripts.valueObjects.HelperConstants;
	
	import moonshine.components.HelperView;
	import moonshine.events.HelperEvent;
	
	public class HelperViewWrapper extends FeathersUIWrapper
	{
		//--------------------------------------------------------------------------
		//
		//  VARIABLES
		//
		//--------------------------------------------------------------------------
		
		public var dependencyCheckUtil:IHelperMoonshineBridge;
		public var environmentUtil:EnvironmentUtils;
		public var isRunningInsideMoonshine:Boolean;
		
		public function get isConfigurationLoaded():Boolean
		{
			return (model.components != null);
		}
		
		private var model:HelperModel = HelperModel.getInstance();
		private var itemsManager:InstallerItemsManager = InstallerItemsManager.getInstance();
		
		//--------------------------------------------------------------------------
		//
		//  CLASS API
		//
		//--------------------------------------------------------------------------
		
		public function HelperViewWrapper(feathersUIControl:HelperView=null)
		{
			super(feathersUIControl);
		}
		
		override public function initialize():void
		{
			super.initialize();
			HelperConstants.IS_RUNNING_IN_MOON = isRunningInsideMoonshine;
			
			//if (!HelperConstants.IS_RUNNING_IN_MOON) rgType.selectedIndex = 1;
			
			if (!model.components)
			{
				itemsManager.dependencyCheckUtil = dependencyCheckUtil;
				itemsManager.environmentUtil = environmentUtil;
				itemsManager.addEventListener(HelperEvent.COMPONENT_DOWNLOADED, onComponentDetected, false, 0, true);
				itemsManager.addEventListener(HelperEvent.ALL_COMPONENTS_TESTED, onAllComponentsDetected, false, 0, true);
				itemsManager.addEventListener(StartupHelper.EVENT_CONFIG_LOADED, onConfigLoaded);
				itemsManager.loadItemsAndDetect();
			}
			else
			{
				onConfigLoaded(null);
			}
			
			this.feathersUIControl.addEventListener(
				HelperView.EVENT_FILTER_TYPE_CHANGED, onFilterTypeChanged, false, 0, true
			);
			this.feathersUIControl.addEventListener(
				HelperView.EVENT_SHOW_ONLY_NEEDS_SETUP_CHANGED, onFilterChange, false, 0, true
			);
			this.feathersUIControl.addEventListener(
				HelperEvent.OPEN_COMPONENT_LICENSE, onComponentLicenseViewRequest, false, 0, true
			)
		}
		
		//--------------------------------------------------------------------------
		//
		//  PUBLIC API
		//
		//--------------------------------------------------------------------------
		
		
		//--------------------------------------------------------------------------
		//
		//  PRIVATE API
		//
		//--------------------------------------------------------------------------
		
		private function filterSearch(filter:Boolean=true):void
		{
			if (!filter)
			{
				//model.packages.filterFunction = null;
				model.components.filterFunction = null;
				//model.packages.refresh();
				model.components.refresh();
				return;
			}
			
			if ((this.feathersUIControl as HelperView).filterTypeIndex == 0)
			{
				/*model.packages.filterFunction = filterPackages;
				model.packages.refresh();*/
			}
			else
			{
				model.components.filterFunction = filterComponents;
				model.components.refresh();
			}
		}
		
		private function filterPackages(item:Object):Boolean
		{
			return !item.isIntegrated;
		}
		
		private function filterComponents(item:Object):Boolean
		{
			return !item.isAlreadyDownloaded;
		}
		
		private function onConfigLoaded(event:HelperEvent):void
		{
			itemsManager.removeEventListener(StartupHelper.EVENT_CONFIG_LOADED, onConfigLoaded);
			onFilterTypeChanged(null);
			
			// pre-filter-out pre-installed items on SDK Installer view
			if (!isRunningInsideMoonshine)
			{
				model.packages.filterFunction = filterPackages;
				model.packages.refresh();
			}
		}
		
		private function onFilterTypeChanged(event:Event):void
		{
			if ((this.feathersUIControl as HelperView).filterTypeIndex == 0)
			{
				(this.feathersUIControl as HelperView).setListPropertiesByFeatureType(model.packages);
			}
			else
			{
				(this.feathersUIControl as HelperView).setListPropertiesBySoftwareType(model.components);
			}
			
			// update filter state
			onFilterChange(null);
		}
		
		private function onFilterChange(event:Event):void
		{
			filterSearch((this.feathersUIControl as HelperView).checkShowOnlyNeedsSetup);
		}
		
		private function onComponentLicenseViewRequest(event:HelperEvent):void
		{
			var stateData:ComponentVO = event.data as ComponentVO;
			if (stateData.type == ComponentTypes.TYPE_FLEX ||
				stateData.type == ComponentTypes.TYPE_SVN || 
				(HelperConstants.IS_MACOS && stateData.type == ComponentTypes.TYPE_GIT)) 
			{
				dispatchEvent(event);
			}
			else 
			{
				navigateToURL(new URLRequest(stateData.licenseUrl), "_blank");
			}
		}
		
		private function onComponentDetected(event:HelperEvent):void
		{
			dispatchEvent(event);
		}
		
		private function onAllComponentsDetected(event:HelperEvent):void
		{
			itemsManager.removeEventListener(HelperEvent.ALL_COMPONENTS_TESTED, onAllComponentsDetected);
			dispatchEvent(event);
		}
	}
}