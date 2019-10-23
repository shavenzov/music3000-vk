package components.library.looperman.events
{
	import flash.events.Event;
	
	public class TagEvent extends Event
	{
		public static const TAG_COMPLETE : String = 'TAG_COMPLETE';
		
		public var genres : Array;
		public var categories : Array;
		public var tempos : Array;
		public var keys : Array;
		
		public function TagEvent( type : String, genres : Array, categories : Array, tempos : Array, keys : Array )
		{
			super( type );
			
			this.genres     = genres;
			this.categories = categories;
			this.tempos     = tempos;
			this.keys       = keys;
		}
		
		override public function clone() : Event
		{
			return new TagEvent( type, genres, categories, tempos, keys );
		}
	}
}