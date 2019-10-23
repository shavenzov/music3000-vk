package components.sequencer.controls.navigatorClasses
{
	import components.Base;
	
	
	public class LeftResizeButton extends Base
	{
		public function LeftResizeButton()
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
					GraphicsPathCommand.LINE_TO,
					GraphicsPathCommand.CURVE_TO
					
				] ),
				Vector.<Number>( [ 0, contentHeight / 2,
					0, 0,
					contentWidth, 0,
					contentWidth, contentHeight,
					0, contentHeight,
					0, contentHeight / 2
				])  
			); 
			*/
			graphics.drawRect( 0, 0, contentWidth, contentHeight );
			graphics.endFill();
		}
	}
}