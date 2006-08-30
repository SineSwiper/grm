<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE stylesheet [
    <!ENTITY tilegraphic "&#xa0;" >
    <!ENTITY literalspace "&#x20;" >
    <!ENTITY cellsplit "&#x253c;" >
]>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output type="html" encoding="utf-8"/>

<xsl:template match="/MapGen">
    <html>
        <head>
            <title> MapGen </title>
            <style type="text/css">
                body        { background: #000; color: #fff; }

                table.map   { border: 1px solid #666; }
                <xsl:if test="/MapGen/option[@name='bounding_box'] and /MapGen/option[@name='cell_size']">table.map {
                     width: <xsl:value-of select="substring-before(/MapGen/option[@name='cell_size']/@value, 'x')*substring-before(/MapGen/option[@name='bounding_box']/@value, 'x')"/>px;
                    height: <xsl:value-of select=" substring-after(/MapGen/option[@name='cell_size']/@value, 'x')* substring-after(/MapGen/option[@name='bounding_box']/@value, 'x')"/>px;
                }</xsl:if>

                td.tile     { width: 15px; height: 15px; background: #222; border: 1px solid #333; }
                <xsl:if test="/MapGen/option[@name='cell_size']">td.tile {
                     width: <xsl:value-of select="substring-before(/MapGen/option[@name='cell_size']/@value, 'x')"/>px;
                    height: <xsl:value-of select=" substring-after(/MapGen/option[@name='cell_size']/@value, 'x')"/>px;
                }</xsl:if>

                td.corridor { background: #ccc; border: 1px dashed #bbb; color: #bbb; }
                td.room     { background: #fff; border: 1px dashed #ddd; color: #ddd; }

                td.northwall { border-top:    1px solid #333; }
                td.eastwall  { border-right:  1px solid #333; }
                td.southwall { border-bottom: 1px solid #333; }
                td.westwall  { border-left:   1px solid #333; }

                td.northdoor { border-top:    2px solid green; }
                td.eastdoor  { border-right:  2px solid green; }
                td.southdoor { border-bottom: 2px solid green; }
                td.westdoor  { border-left:   2px solid green; }

                td.northdoorsecret { border-top:    2px solid blue; }
                td.eastdoorsecret  { border-right:  2px solid blue; }
                td.southdoorsecret { border-bottom: 2px solid blue; }
                td.westdoorsecret  { border-left:   2px solid blue; }

                td.northdoorlocked { border-top:    2px solid red; }
                td.eastdoorlocked  { border-right:  2px solid red; }
                td.southdoorlocked { border-bottom: 2px solid red; }
                td.westdoorlocked  { border-left:   2px solid red; }

                td.northdoorsecretlocked { border-top:    2px solid purple; }
                td.eastdoorsecretlocked  { border-right:  2px solid purple; }
                td.southdoorsecretlocked { border-bottom: 2px solid purple; }
                td.westdoorsecretlocked  { border-left:   2px solid purple; }
            </style>
        </head>
        <body>
            <table cellspacing="0" cellpadding="0" class="map">
                <xsl:for-each select="map/row">
                    <tr> <xsl:variable name="y" select="position()"/>
                        <xsl:for-each select="tile">
                            <td align="center" valign="center"> <xsl:variable name="x" select="position()"/>
                                <xsl:attribute name="class">tile <xsl:value-of select="@type"/> <xsl:for-each select="closure">
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of select="@dir"/>
                                    <xsl:value-of select="@type"/>
                                    <xsl:if test='@type="door" and @secret="yes"'>secret</xsl:if>
                                    <xsl:if test='@type="door" and (@locked="yes" or @stuck="yes")'>locked</xsl:if>
                                </xsl:for-each>
                                <xsl:if test="@locked='yes'">
                                    locked
                                </xsl:if>
                                </xsl:attribute>
                                <xsl:attribute name="title">(<xsl:value-of select="$x-1"/>,<xsl:value-of select="$y-1"/>)</xsl:attribute>
                                &tilegraphic;
                            </td>
                        </xsl:for-each>
                    </tr>
                </xsl:for-each>
            </table>
        </body>
    </html>
</xsl:template>

</xsl:stylesheet>
