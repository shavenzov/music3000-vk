package com.audioengine.core
{
	public interface IInput
	{
		function get input() : IProcessor;
		function set input( i : IProcessor ) : void	
	}
}