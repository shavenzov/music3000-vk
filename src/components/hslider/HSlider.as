package components.hslider
{
    import com.utils.NumberUtils;
    
    import mx.controls.HSlider;
	
	public class HSlider extends mx.controls.HSlider
	{
		public function HSlider()
		{
			super();
			dataTipFormatFunction = formatFunction;
		}
	    
		private function formatFunction( value : Number ) : Object
		{
			return NumberUtils.roundTo( value, 2 ).toString();
		}	
	}
}