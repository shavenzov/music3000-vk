package components.sequencer.timeline.visual_sample
{
	import components.Base;
	
	import flash.events.MouseEvent;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.setInterval;
	
	import mx.core.FTETextField;
	
	public class Preloader extends Base
	{
		private var _percent   : int;
		
		/**
		 * Отображение процента загрузки 
		 */		
		private var label : FTETextField;
		
		private var indicator : Indicator;
		
		public function Preloader()
		{
			super();
			
			indicator = new Indicator();
			
			label = new FTETextField();
			label.embedFonts = true;
			
			label.defaultTextFormat = new TextFormat( 'Calibri', 12, 0xffffff, true );
			label.selectable = false;
			label.autoSize = TextFieldAutoSize.RIGHT;
			
			addChild( indicator );
			addChild( label );
			
			percent = 0;
			
		}
		
		/**
		 * Процент отображения индикации 
		 * @return 
		 * 
		 */		
		public function get percent() : int
		{
			return _percent;
		}
		
		public function set percent( value : int ) : void
		{
			_percent = value;
			
			indicator.progress.gotoAndStop( _percent );
			label.text = value + '%';
			
			_needMeasure = true;
			_needUpdate = true;
			touch();
		}
		
		public function setProgress( value : int, total : int ) : void
		{
			percent = Math.round( value * 100 / total );
		}	
		
		override protected function update():void
		{
			label.x = ( contentWidth - label.textWidth ) / 2;
			label.y = 17.5;
			
			graphics.beginFill( 0x00ff00, 0 );
			graphics.drawRect( 0, 0, contentWidth, contentHeight );
			graphics.endFill();
		}	
		
		override protected function measure() : void
		{
			contentWidth = 17.5;
			contentHeight = 17.5 + label.textHeight;
		}	
	}
}