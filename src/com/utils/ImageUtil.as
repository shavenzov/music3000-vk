package com.utils
{
	import flash.display.DisplayObject;

	public class ImageUtil
	{
		public static function resizeTo( image : DisplayObject, size : Number ) : void
		{
			var decCount : Number = 0.0;
			
			if ( image.width >= image.height )
			{
				decCount = image.width - size;
				image.width = size;
				image.height -= decCount;
			}
			else
			{
				decCount = image.height - size;
				image.height = size;
				image.width -= decCount;
			}
		}
	}
}