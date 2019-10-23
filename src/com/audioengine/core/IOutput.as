package com.audioengine.core
{
	public interface IOutput
	{
		function get output() : IProcessor;
		function set output( i : IProcessor ) : void	
	}
}