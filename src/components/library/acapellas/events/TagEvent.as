package components.library.acapellas.events
{
	import flash.events.Event;
	
	public class TagEvent extends Event
	{
		public static const TAG_COMPLETE : String = 'TAG_COMPLETE';
		
		public var genres    : Array;
		public var genders   : Array;
		public var tempos    : Array;
		public var keys      : Array;
		public var styles    : Array;
		public var autotunes : Array;
		
		public function TagEvent( type : String, genres : Array, genders : Array, tempos : Array, keys : Array, styles : Array, autotunes : Array )
		{
			super( type );
			
			this.genres     = genres;
			this.genders    = genders;
			this.tempos     = tempos;
			this.keys       = keys;
			this.styles     = styles;
			this.autotunes  = autotunes;
		}
		
		override public function clone() : Event
		{
			return new TagEvent( type, genres, genders, tempos, keys, styles, autotunes );
		}
	}
}