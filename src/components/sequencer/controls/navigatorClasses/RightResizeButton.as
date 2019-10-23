package components.sequencer.controls.navigatorClasses
{
	import components.Base;
	
	public class RightResizeButton extends Base
	{
		public function RightResizeButton()
		{
			super();
		}
		
		override protected function measure():void
		{
			contentWidth = 8;
		}
		
		override protected function update():void
		{
			graphics.clear();
			graphics.beginFill( 0xFFFFF, 0.0 );
			/*
			graphics.drawPath( 
				Vector.<int>( [ GraphicsPathCommand.MOVE_TO,
					GraphicsPathCommand.CURVE_TO,
					GraphicsPathCommand.CURVE_TO,
					GraphicsPathCommand.LINE_TO ] ),
				Vector.<Number>( [ 0.0, 0.0,
					contentWidth, 0,
					contentWidth, contentHeight / 2,
					contentWidth, contentHeight,
					0, contentHeight,
					0, 0
				])  
			);
			*/
			graphics.drawRect( 0, 0, contentWidth, contentHeight );
			graphics.endFill();
		}
	}
}