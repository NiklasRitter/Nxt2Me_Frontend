import 'package:event_app/src/constants.dart';
import 'package:flutter/material.dart';

class AcknowledgementPage extends StatelessWidget {
  const AcknowledgementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Constants.backgroundColor,
        automaticallyImplyLeading: false,
        title: const Text(
          'Acknowledgement',
          style: MyTextStyle(
            cColor: Colors.white,
            cFontSize: Constants.pageHeadingFontSize,
          ),
        ),
        leading: IconButton(
          iconSize: 22,
          padding: const EdgeInsets.all(5.0),
          splashRadius: 25,
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () async {
            Navigator.pop(context);
          },
        ),
        centerTitle: false,
        elevation: 0,
      ),
      backgroundColor: Constants.backgroundColor,
      body: const SingleChildScrollView(
        reverse: false,
        primary: false,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(10, 10, 10, 10),
            child: Text(
              'We use these open source libraries to make Nxt2Me: \n' +
              '\n App: \n cached_network_image \n connectivity_plus \n crop_your_image \n firebase_core \n firebase_messaging \n '+
                  'flutter_image_compress \n flutter_local_notifications \n flutter_secure_storage \n geolocator \n ' +
                  'google_maps_flutter \n google_sign_in \n http \n image_picker \n implicitly_animated_reorderable_list \n ' +
                  'intl \n material_floating_searchbar \n page_transition \n path \n permission_handler \n '+
                  'property_change_notifier \n pull_to_refresh \n sqflite \n ' +
                  '\n Server: \n axios \n bad-words \n bcrypt \n config \n cors \n dayjs \n express \n express-rate-limit \n ' +
                  'googleapis \n jsonwebtoken \n lodash \n mongoose \n multer \n nodemailer \n pino \n pino-pretty \n ' +
                  'prom-client \n typescript \n ts-node \n zod',
              textAlign: TextAlign.start,
              overflow: TextOverflow.clip,
              style: MyTextStyle(
                cFontSize: Constants.flowingTextFontSize,
              ),
              maxLines: 100,
            ),
          ),
        ),
      ),
    );
  }
}
