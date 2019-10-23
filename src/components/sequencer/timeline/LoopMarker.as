package components.sequencer.timeline
{
	import flash.display.BlendMode;
	

	public class LoopMarker extends Marker
	{
		/**
		 * Длина зацикленного фрагмента в фреймах 
		 */		
		private var _loopDuration : Number;
		
		public function LoopMarker()
		{
			super();
			
			_stickToGrid = false;
			_snapToGrid = true;
			_snapToGridThenXChange = true;
			
			_cursorWidth  = 0.0;
			_cursorHeight = Settings.RULLER_HEIGHT;
			_offset       = 0.0;
			
			//blendMode = BlendMode.
		}
		
		public function get loopDuration() : Number
		{
			return _loopDuration;
		}
		
		public function set loopDuration( value : Number ) : void
		{
			if ( value != _loopDuration )
			{
				_loopDuration = value;
				_needUpdate = true;
				_needMeasure = true;
			}	
		}
		
		public function get end() : Number
		{
			return _position + _loopDuration;
		}
		
		override protected function measure():void
		{
			contentWidth = _loopDuration / _scale;
		}	
		
		override protected function correctPosition( pos : Number ) : Number
		{
			if ( pos < 0 ) pos = 0;
			if ( pos > ( _duration - _loopDuration ) ) pos = _duration - _loopDuration;
			
			return pos;
		}	
		
		override protected function draw():void
		{
			    graphics.clear();
				graphics.beginFill( 0xffffff, 0.25 );
				graphics.drawRect( 0, 0, contentWidth, _cursorHeight ); 
				graphics.endFill();  
		}
	}
}