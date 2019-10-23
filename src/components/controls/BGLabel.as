package components.controls
{
	import flash.display.GraphicsPathCommand;
	
	import mx.controls.Label;
	
	public class BGLabel extends Label
	{
		private var _fill           : uint = 0x0099FF;
		private var _fillAlpha      : Number = 0.85;
		
		public function BGLabel()
		{
			super();
		}
		
		public function get fill() : uint
		{
			return _fill;
		}
		
		public function set fill( value : uint ) : void
		{
			_fill = value;
			invalidateDisplayList();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			unscaledHeight -= 2;
			
			graphics.clear();
			graphics.beginFill( _fill, _fillAlpha );
			graphics.drawPath( Vector.<int>( [ GraphicsPathCommand.MOVE_TO, GraphicsPathCommand.LINE_TO, 
				                               GraphicsPathCommand.LINE_TO, GraphicsPathCommand.LINE_TO,
											   GraphicsPathCommand.LINE_TO, GraphicsPathCommand.LINE_TO ] ),
				               Vector.<Number>( 
								                [
								                  0, 0,
												  unscaledWidth, 0,
												  unscaledWidth + 10, unscaledHeight / 2,
												  unscaledWidth, unscaledHeight,
												  0, unscaledHeight,
												  0, 0
												]	 
								               )
							   );
			
			graphics.endFill();
		}
	}
}