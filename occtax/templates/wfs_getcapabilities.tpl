<?xml version="1.0" encoding="UTF-8"?>
<WFS_Capabilities updateSequence="0" version="1.0.0" xmlns="http://www.opengis.net/wfs" xmlns:gml="http://www.opengis.net/gml" xmlns:ogc="http://www.opengis.net/ogc" xmlns:ows="http://www.opengis.net/ows" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.opengis.net/wfs http://schemas.opengis.net/wfs/1.0.0/WFS-capabilities.xsd">
 <Service>
  <Name>WFS</Name>
  <Title><![CDATA[{$title}]]></Title>
  <Abstract><![CDATA[{$abstract}]]></Abstract>
  <OnlineResource/>
  <Fees>conditions unknown</Fees>
  <AccessConstraints>None</AccessConstraints>
 </Service>
 <Capability>
  <Request>
   <GetCapabilities>
    <DCPType>
     <HTTP>
      <Get onlineResource="{$url}"/>
     </HTTP>
    </DCPType>
    <DCPType>
     <HTTP>
      <Post onlineResource="{$url}"/>
     </HTTP>
    </DCPType>
   </GetCapabilities>
   <DescribeFeatureType>
    <SchemaDescriptionLanguage>
     <XMLSCHEMA/>
    </SchemaDescriptionLanguage>
    <DCPType>
     <HTTP>
      <Get onlineResource="{$url}"/>
     </HTTP>
    </DCPType>
    <DCPType>
     <HTTP>
      <Post onlineResource="{$url}"/>
     </HTTP>
    </DCPType>
   </DescribeFeatureType>
   <GetFeature>
    <ResultFormat>
     <GML2/>
     <GML3/>
     <GeoJSON/>
    <SHP/><XLSX/><ODS/><KML/><MIF/><TAB/><CSV/></ResultFormat>
    <DCPType>
     <HTTP>
      <Get onlineResource="{$url}"/>
     </HTTP>
    </DCPType>
    <DCPType>
     <HTTP>
      <Post onlineResource="{$url}"/>
     </HTTP>
    </DCPType>
   </GetFeature>
   <Transaction>
    <DCPType>
     <HTTP>
      <Post onlineResource="{$url}"/>
     </HTTP>
    </DCPType>
   </Transaction>
  </Request>
 </Capability>
 <FeatureTypeList>
  <Operations>
   <Query/>
  </Operations>
  <FeatureType>
   <Name>export_observation</Name>
   <Title>export_observation</Title>
   <Abstract>{$abstract}</Abstract>
   <SRS>{$srs}</SRS>
   <Operations>
    <Query/>
   </Operations>
   <LatLongBoundingBox maxx="{$maxx}" maxy="{$maxy}" minx="{$minx}" miny="{$miny}"/>
  </FeatureType>
 </FeatureTypeList>
 <ogc:Filter_Capabilities>
  <ogc:Spatial_Capabilities>
   <ogc:Spatial_Operators>
    <ogc:BBOX/>
   </ogc:Spatial_Operators>
  </ogc:Spatial_Capabilities>
  <ogc:Scalar_Capabilities>
   <ogc:Comparison_Operators>
   </ogc:Comparison_Operators>
  </ogc:Scalar_Capabilities>
 </ogc:Filter_Capabilities>
</WFS_Capabilities>
