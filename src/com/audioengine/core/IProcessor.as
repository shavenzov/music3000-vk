package com.audioengine.core
{
	import flash.utils.ByteArray;

	public interface IProcessor
	{	
		function render( data : ByteArray, bytes : uint ) : void	
	}
}