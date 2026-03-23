import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FullScreenMapViewer extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? title;

  const FullScreenMapViewer({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title,
  });

  @override
  State<FullScreenMapViewer> createState() => _FullScreenMapViewerState();
}

class _FullScreenMapViewerState extends State<FullScreenMapViewer> {
  late LatLng _location;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _location = LatLng(widget.latitude, widget.longitude);
    _markers.add(
      Marker(
        markerId: const MarkerId('issueLocation'),
        position: _location,
        infoWindow: InfoWindow(title: widget.title ?? 'Issue Location'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Location Preview'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _location,
          zoom: 16.5,
        ),
        markers: _markers,
        zoomControlsEnabled: true,
        zoomGesturesEnabled: true,
        myLocationButtonEnabled: false,
        mapToolbarEnabled: true,
        compassEnabled: true,
      ),
    );
  }
}
