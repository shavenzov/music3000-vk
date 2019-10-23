package components.welcome
{
	import components.welcome.events.GoToEvent;
	
	import spark.components.NavigatorContent;
	
	public class NavigatorContent extends spark.components.NavigatorContent
	{
		public var initializedAction : GoToEvent;
		public var groupIndex : int;
		
		public function NavigatorContent()
		{
			super();
		}
	}
}