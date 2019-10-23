package components.sequencer
{
	public class ColorPalette
	{
		private static const COLORS : Vector.<uint> = Vector.<uint>( [ 0xFFCC66, 0xFF9900, 0xFFCC99, 0xFF6633, 0xFFCCCC, 0xCC9999, 0xFF6699, 0xFF99CC, 0xCC66CC, 0xFF66CC, 0xFFCCFF, 0xCC99CC, 0xCC66FF, 0xCC99FF, 0x9966CC, 0xCCCCFF  ] );
		
		/**
		 * Цвет дорожки в отключенном состоянии 
		 */		
		public static const DISABLED_COLOR  : uint = 0xC0C0C0;
		
		/**
		 * Цвет сэмпла в состоянии ошибки 
		 */		
		public static const ERROR_COLOR : uint = 0xFF0000;
		
		public static function getColor( n : int ) : uint
		{
			if ( n < COLORS.length )
			{
				return COLORS[ n ];
			}
			
			return 0x00FF00;
		}	
	}
}