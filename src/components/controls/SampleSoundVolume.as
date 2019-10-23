package components.controls
{
	import classes.SamplePlayer;
	import classes.SamplePlayerImplementation;
	
	import components.managers.PopUpManager;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.core.FlexGlobals;
	import mx.events.FlexEvent;
	import mx.events.SliderEvent;

	public class SampleSoundVolume extends LinkButton
	{
		private var slider : PopupVSlider;
		private var player : SamplePlayerImplementation;
		
		public function SampleSoundVolume()
		{
			super();
			focusEnabled = false;
			tabEnabled   = false;
			useHandCursor = false;
			player = SamplePlayer.impl;
		}
		
		override protected function measure() : void
		{
			super.measure();
			
			measuredWidth = 23;
			measuredHeight = 23;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			toolTip = "Щелкни для изменения громкости прослушивания сэмплов";
			setStyle( 'icon', Assets.SOUND );
			addEventListener( MouseEvent.CLICK, onClick );
		}
		
		private var sliderX   : Number;
		
		private function showSlider() : void
		{
			if ( ! slider )
			{
				slider = new PopupVSlider();
				slider.minimum = 0.0;
				slider.maximum = 100.0;
				
				slider.liveDragging = true;
				slider.snapInterval = 1;
				slider.height = 100;
				slider.labels = [ slider.minimum, slider.maximum ];
				slider.tickValues = slider.labels;
				
				slider.setStyle( 'dataTipPrecision' , 0 );
				slider.addEventListener( SliderEvent.CHANGE, onSliderChange );
				
				PopUpManager.addPopUp( slider, DisplayObject( FlexGlobals.topLevelApplication ) );
				slider.show();
				
				slider.validateNow();
				slider.value = player.volume * 100;
				sliderX = mouseX;
				moveSlider();
				
				stage.addEventListener( MouseEvent.CLICK, onStageClick );
				stage.addEventListener( Event.RESIZE, onResize );
			}
		}
		
		private function onStageClick( e : MouseEvent ) : void
		{
			if ( ! slider.hitTestPoint( e.stageX, e.stageY ) )
			{
				hideSlider();
			}
		}
		
		private function hideSlider() : void
		{
			stage.removeEventListener( MouseEvent.CLICK, onStageClick );
			stage.removeEventListener( Event.RESIZE, onResize );
			
			slider.removeEventListener( SliderEvent.CHANGE, onSliderChange );
			slider.addEventListener( FlexEvent.HIDE, onSliderHide );
			slider.hide();
		}
		
		private function onSliderHide( e : FlexEvent ) : void
		{
			PopUpManager.removePopUp( slider );
			slider.removeEventListener( FlexEvent.HIDE, onSliderHide );
			slider = null;
		}
		
		private function onSliderChange( e : SliderEvent ) : void
		{
			player.volume = e.value / 100;
		}
		
		private function moveSlider() : void
		{
			var pos : Point = localToGlobal( new Point( sliderX, 0 ) );
			slider.move(  pos.x - ( slider.width + PopupVSlider._left + PopupVSlider._right ) / 2, pos.y - slider.height - 3 ); 
		}
		
		private function onResize( e : Event ) : void
		{
			moveSlider();
		}
		
		private function onClick( e : MouseEvent ) : void
		{
			callLater( showSlider );
		}
	}
}