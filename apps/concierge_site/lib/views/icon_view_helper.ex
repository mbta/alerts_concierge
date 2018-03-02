defmodule ConciergeSite.IconViewHelper do
  import Phoenix.HTML, only: [raw: 1]

  @spec icon(atom) :: Phoenix.HTML.safe
  def icon(:red), do: subway("#da291c")
  def icon(:blue), do: subway("#003da5")
  def icon(:orange), do: subway("#ed8b00")
  def icon(:green), do: subway("#00843d")
  def icon(:bus) do
    raw("""
    <svg width="30" height="30" fill="#000" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 50 50">
    <circle fill="#ffce0c" stroke="#ffce0c" stroke-width="1" r="20" cx="20" cy="20" transform="translate(1,1)"></circle>
    <g transform="translate(10,10) scale(1.4)">
    <path d="M11 15H5c-.005.553-.446 1-.999 1H2.999A.999.999 0 0 1 2 15c-.553-.004-1-.45-1-1.002v-.496-12.5C1 .449 1.45 0 2.007 0h11.986C14.55 0 15 .445 15 1.002v12.996c0 .55-.446.998-1 1.002-.005.553-.446 1-.999 1h-1.002A.999.999 0 0 1 11 15zM9 4v6h5V4H9zM2 4v6h5V4H2zm2-3v2h8V1H4zm8 11c0 .556.448 1 1 1 .556 0 1-.448 1-1 0-.556-.448-1-1-1-.556 0-1 .448-1 1zm-3 0c0 .556.448 1 1 1 .556 0 1-.448 1-1 0-.556-.448-1-1-1-.556 0-1 .448-1 1zm-4 0c0 .556.448 1 1 1 .556 0 1-.448 1-1 0-.556-.448-1-1-1-.556 0-1 .448-1 1zm-3 0c0 .556.448 1 1 1 .556 0 1-.448 1-1 0-.556-.448-1-1-1-.556 0-1 .448-1 1z"></path>
    </g></svg>
    """)
  end
  def icon(:commuter_rail) do
    raw("""
    <svg width="30" height="30" fill="#fff" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 50 50">
    <circle fill="#80276c" stroke="#80276c" stroke-width="1" r="20" cx="20" cy="20" transform="translate(1,1)"></circle>
    <g transform="translate(10,10) scale(1.4)">
    <path d="M2 5.34V3c0-.552.432-1.144.95-1.317L7.05.317c.524-.175 1.382-.173 1.9 0l4.1 1.366c.524.175.95.76.95 1.317v2.34l1 .285v5.565c0 .55-.45.996-1.007.996H2.007A1.005 1.005 0 0 1 1 11.19V5.625l1-.286zM13 10a1 1 0 1 0 0-2 1 1 0 0 0 0 2zM3 10a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm0-7v2l4-1V2L3 3zm6-1v2l4 1V3L9 2zM2 13h12v.5c0 .276-.229.5-.5.5h-11a.505.505 0 0 1-.5-.5V13zm3 1h2l-2 2H3l2-2zm4 0h2l2 2h-2l-2-2z"></path>
    </g></svg>
    """)
  end
  def icon(:mattapan) do
    """
    <svg width="30" height="30" fill="#fff" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 50 50">
    <circle fill="#da291c" stroke="#da291c" stroke-width="1" r="20" cx="20" cy="20" transform="translate(1,1)"></circle>
    <g transform="translate(10,10) scale(1.4)">
    <path d="M2 13V2.995C2 2.445 2.456 2 3.002 2h9.996C13.55 2 14 2.456 14 2.995V13c0 .552-.456 1-1.002 1H3.002A.999.999 0 0 1 2 13zm2.667 1h6.666L12 16H4l.667-2zM4 1c0-.552.453-1 .997-1h6.006c.55 0 .997.444.997 1v1H4V1zm0 2.5c0 .268.224.5.5.5h7c.27 0 .5-.224.5-.5 0-.268-.224-.5-.5-.5h-7c-.27 0-.5.224-.5.5zM3 6v3c0 .556.452 1 1.01 1h1.98A1 1 0 0 0 7 9V6c0-.556-.452-1-1.01-1H4.01A1 1 0 0 0 3 6zm6 0v3c0 .556.452 1 1.01 1h1.98A1 1 0 0 0 13 9V6c0-.556-.452-1-1.01-1h-1.98A1 1 0 0 0 9 6zm-2 6c0 .556.448 1 1 1 .556 0 1-.448 1-1 0-.556-.448-1-1-1-.556 0-1 .448-1 1z"></path>
    </g></svg>
    """
  end
  def icon(:ferry) do
    raw("""
    <svg width="30" height="30" fill="#fff" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 50 50">
    <circle fill="#008eaa" stroke="#008eaa" stroke-width="1" r="20" cx="20" cy="20" transform="translate(1,1)"></circle>
    <g transform="translate(10,10) scale(1.4)">
    <path d="M2 7V3l6-3 6 3v4l2 1s-3.98 4-4 7c-.408 0-1-1-2-1s-1 1-2 1-1-1-2-1-1.488 1-2 1c.044-3-4-7-4-7l2-1zm1-3v2l4-2V2L3 4zm6-2v2l4 2V4L9 2z"></path>
    </g></svg>
    """)
  end

  defp subway(color) do
    raw("""
    <svg width="30" height="30" fill="#fff" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 50 50">
    <circle fill="#{color}" stroke="#{color}" stroke-width="1" r="20" cx="20" cy="20" transform="translate(1,1)"></circle>
    <g transform="translate(10,10) scale(1.4)">
    <path d="M10 6h6V2H0v4h6v10h4V6z"></path>
    </g></svg>
    """)
  end
end
