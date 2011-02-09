/*
 * Copyright (c) 2009-2011 the original author or authors
 * 
 * Permission is hereby granted to use, modify, and distribute this file 
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.swiftsuspenders.injectionpoints
{
	import org.swiftsuspenders.InjectionRule;
	import org.swiftsuspenders.Injector;
	import org.swiftsuspenders.InjectorError;

	public class PropertyInjectionPoint extends InjectionPoint
	{
		/*******************************************************************************************
		*								private properties										   *
		*******************************************************************************************/
		private var _propertyName : String;
		private var _propertyType : String;
		private var _injectionName : String;
		private var _injectionIsOptional : Boolean;

		
		/*******************************************************************************************
		*								public methods											   *
		*******************************************************************************************/
		public function PropertyInjectionPoint(node : XML)
		{
			super(node);
		}
		
		override public function applyInjection(target : Object, injector : Injector) : Object
		{
			var rule : InjectionRule = injector.getMapping(Class(
					injector.getApplicationDomain().getDefinition(_propertyType)), _injectionName);
			var injection : Object = rule && rule.apply(injector);
			if (injection == null)
			{
				if (_injectionIsOptional)
				{
					return target;
				}
				throw(new InjectorError(
						'Injector is missing a rule to handle injection into property "' +
						_propertyName + '" of object "' + target +
						'". Target dependency: "' + _propertyType + '", named "' + _injectionName +
						'"'));
			}
			target[_propertyName] = injection;
			return target;
		}


		/*******************************************************************************************
		*								protected methods										   *
		*******************************************************************************************/
		override protected function initializeInjection(node : XML) : void
		{
			_propertyType = node.parent().@type.toString();
			_propertyName = node.parent().@name.toString();
			_injectionName = node.arg.(@key == 'name').attribute('value').toString();
			_injectionIsOptional = node.arg.(@key == 'optional' &&
					(@value == 'true' || @value == '1')).length() != 0;
		}
	}
}