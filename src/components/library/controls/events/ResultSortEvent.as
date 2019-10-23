package components.library.controls.events
{
	import flash.events.Event;
	
	public class ResultSortEvent extends Event
	{
		public static const SORT_PARAMS_CHANGED : String = 'sortParamsChanged';
		
		public var sortField : String;
		public var descending : Boolean;
		
		public function ResultSortEvent( type:String, sortField : String, descending : Boolean )
		{
			super(type);
			this.sortField = sortField;
			this.descending = descending;
		}
		
		override public function clone() : Event
		{
			return new ResultSortEvent( type, sortField, descending );
		}
	}
}