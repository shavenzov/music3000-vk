package components.sequencer.controls
{	
	import com.utils.NumberUtils;
	
	import mx.controls.HSlider;
	import mx.controls.sliderClasses.SliderThumb;

	public class VolumeControl extends HSlider
	{
		public function VolumeControl()
		{
			super();
			tabEnabled = false;
			focusEnabled = false;
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if ( ! initialized )
			{
				dataTipFormatFunction = formatFunction;
				minimum = 0.0;
				maximum = Settings.MAX_TRACK_SOUND_VOLUME;
				value = Settings.DEFAULT_TRACK_SOUND_VOLUME;
				liveDragging = true
					
				var slider : SliderThumb = getThumbAt( 0 );
				    slider.focusEnabled = false;
					slider.tabEnabled = false;
			}	
		}	
		
		private function formatFunction( value : Number ) : Object
		{
			return 'Громкость:' + NumberUtils.valueToPercent( value, maximum ).toString() + '%';
		}
	}
}