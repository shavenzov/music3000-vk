package com.utils
{
	public class FileUtils
	{
		public static function removeFileExtension( fileName : String ) : String
		{   
			var i : int = fileName.length - 1;
			
			while( i >= 0 )
			{
				if ( fileName.charAt( fileName.length - i ) == '.' )
				{
					return fileName.substr( 0, fileName.length - i );
				}	  
				
				i --;
			}
			
			return fileName;
		}	
	}
}