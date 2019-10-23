package components.library.events
{
	import flash.events.Event;
	
	import classes.BaseDescription;
	
	public class DataEvent extends Event
	{
		public static const DATA_COMPLETE : String = 'DATA_COMPLETE';
		
		public var data  : Vector.<BaseDescription>;
		public var count : int;
		
		public function DataEvent( type : String, data : Vector.<BaseDescription>, count : int )
		{
			super( type );
			
			this.data = data;
			this.count = count;	
		}
		
		override public function clone():Event
		{
			return new DataEvent( type, data, count );
		}
	}
}