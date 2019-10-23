package components.sequencer.timeline
{
	import components.menu.Menu;
	import components.sequencer.timeline.visual_sample.BaseVisualSample;
	
	import flash.display.DisplayObjectContainer;

	public class SampleMenu
	{
		public static const DELETE : String = "del";
		public static const COPY   : String = "copy";
		public static const CUT    : String = "cut";
		public static const INVERT : String = "invert";
		public static const LOOP   : String = "loop";
		
		public static const RELOAD : String = "reload";
		
		public static function getSampleMenu( parent : DisplayObjectContainer, s : Object ) : Menu
		{
			var items : Array = [
				{ label : "удалить", id : DELETE, source : s },
				{ label : "вырезать", id : CUT, source : s },
				{ label : "копировать", id : COPY, source : s },
				{ label : "обратить", id : INVERT, source : s },
				/*
				{ label : "", enabled : false },
				*/
				{ label : "автоподстройка", id : LOOP, type : "check", toggled : s.note.source.loop, source : s }
			];
				
			
			return Menu.createMenu( parent, items );
		}
		
		public static function getErrorMenu( parent : DisplayObjectContainer, s : Object ) : Menu
		{
			var items : Array = [
				{ label : "обновить", id : RELOAD, source : s }
			];
			
			return Menu.createMenu( parent, items );
		}
	}
}