package com.audioengine.calculations
{
	import flash.utils.ByteArray;

	public interface ICalculation
	{
		function get length() : int
		function set length( value : int ) : void
		
		function calculate( data : ByteArray ) : void
		function invalidateBuild() : void	
	}
}