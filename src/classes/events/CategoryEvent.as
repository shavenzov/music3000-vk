package classes.events
{
	import flash.events.Event;
	
	public class CategoryEvent extends Event
	{
		public static const CHANGE : String = 'CHANGE';
		
		public var category    : String;
		public var trackNumber : uint;
		
		public function CategoryEvent( type:String, category : String, trackNumber : uint )
		{
			super( type );
			this.category = category;
			this.trackNumber = trackNumber;
		}
		
		override public function clone():Event
		{
			return new CategoryEvent( type, category, trackNumber ); 
		}
	}
}