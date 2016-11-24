<schema xmlns:ogc="http://www.opengis.net/ogc" elementFormDefault="qualified" targetNamespace="http://www.qgis.org/gml" version="1.0" xmlns="http://www.w3.org/2001/XMLSchema" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:gml="http://www.opengis.net/gml" xmlns:qgs="http://www.qgis.org/gml">
 <import namespace="http://www.opengis.net/gml" schemaLocation="http://schemas.opengis.net/gml/2.1.2/feature.xsd"/>
 <element type="qgs:export_observationType" name="export_observation" substitutionGroup="gml:_Feature"/>
 <complexType name="export_observationType">
  <complexContent>
   <extension base="gml:AbstractFeatureType">
    <sequence>
     <element minOccurs="0" maxOccurs="1" type="gml:PointPropertyType" name="geometry"/>
     {foreach $attributes as $name=>$type}
     <element type="{$type}" name="{$name}"/>
     {/foreach}
    </sequence>
   </extension>
  </complexContent>
 </complexType>
</schema>
