import os

#------------------------------------------------------------------------------

from kivy.clock import Clock

#------------------------------------------------------------------------------

from components import screen
from components import dialogs
from components import snackbar

from lib import system
from lib import api_client
from lib import websock

#------------------------------------------------------------------------------

_Debug = False

#------------------------------------------------------------------------------

identity_details_temlate_text = """
[size={text_size}][color=#909090]name:[/color] [b]{name}[/b]

[color=#909090]global ID:[/color] [b]{global_id}[/b]

[color=#909090]network interfaces:[/color]
{contacts}

[color=#909090]identity servers:[/color]
{sources}

[color=#909090]created:[/color] {date}

[color=#909090]revision:[/color] {revision}

[color=#909090]version:[/color]
[size={small_text_size}]{version}[/size]

[color=#909090]public key:[/color]
[size={small_text_size}][font=RobotoMono-Regular]{publickey}[/font][/size]

[color=#909090]digital signature:[/color]
[size={small_text_size}][font=RobotoMono-Regular]{signature}[/font][/size]

[/size]
"""

create_new_identity_text = """
To be able to start using BitDust, please [u][color=#0000ff][ref=new_identity]create new identity[/ref][/color][/u] first
"""

#------------------------------------------------------------------------------

class MyIDScreen(screen.AppScreen):

    def get_icon(self):
        return 'account-box'

    def get_title(self):
        return 'my identity'

    def on_enter(self, *args):
        self.ids.action_button.close_stack()
        self.ids.state_panel.attach(automat_id='service_identity_propagate')
        api_client.identity_get(cb=self.on_identity_get_result)

    def on_leave(self, *args):
        self.ids.action_button.close_stack()
        self.ids.state_panel.release()

    def on_identity_get_result(self, resp):
        if not websock.is_ok(resp):
            self.ids.my_id_details.text = create_new_identity_text
            return
        result = websock.response_result(resp)
        if not result:
            self.ids.my_id_details.text = create_new_identity_text
            return
        self.ids.my_id_details.text = identity_details_temlate_text.format(
            text_size='{}sp'.format(self.app().font_size_normal_absolute),
            small_text_size='{}sp'.format(self.app().font_size_small_absolute),
            name=result.get('name', ''),
            global_id=result.get('global_id', ''),
            publickey=result.get('publickey', ''),
            signature=result.get('signature', ''),
            date=result.get('date', ''),
            version=result.get('version', ''),
            revision=result.get('revision', ''),
            sources='\n'.join(result.get('sources', [])),
            contacts='\n'.join(result.get('contacts', [])),
        )

    def on_my_id_details_ref_pressed(self, *args):
        if _Debug:
            print('MyIDScreen.on_my_id_details_ref_pressed', args)
        if args[1] == 'new_identity':
            self.main_win().select_screen('new_identity_screen')

    def on_action_button_clicked(self, btn):
        if _Debug:
            print('MyIDScreen.on_action_button_clicked', btn.icon)
        self.ids.action_button.close_stack()
        if btn.icon == 'shield-key':
            if system.is_android():
                destination_filepath = os.path.join('/storage/emulated/0/', 'bitdust_key.txt')
            else:
                destination_filepath = os.path.join(os.path.expanduser('~'), 'bitdust_key.txt')
            api_client.identity_backup(
                destination_filepath=destination_filepath,
                cb=lambda resp: self.on_identity_backup_result(resp, destination_filepath),
            )
        elif btn.icon == 'cellphone-erase':
            dialogs.open_yes_no_dialog(
                title='This will erase your identity and the private key and all data will be lost',
                text='WARNING!\n\nAll your data will become\ncompletely inaccessible\nwithout a private key',
                cb=self.on_confirm_erase_my_id,
            )
        elif btn.icon == 'lan-pending':
            api_client.network_reconnect(cb=self.on_network_reconnect_result)
        elif btn.icon == 'cog-refresh':
            self.app().restart_engine()
            snackbar.info(text='BitDust background process is restarting')
        elif btn.icon == 'power':
            self.app().stop_engine()
            snackbar.info(text='BitDust background process will be stopped')

    def on_confirm_erase_my_id(self, answer):
        if _Debug:
            print('MyIDScreen.on_confirm_erase_my_id', answer)
        if answer == 'yes':
            api_client.process_stop()
            self.main_win().engine_is_on = False
            Clock.schedule_once(self.on_process_stop_result_erase_my_id, 1)

    def on_network_reconnect_result(self, resp):
        if not websock.is_ok(resp):
            snackbar.error(text='disconnected: %s' % websock.response_err(resp))
        else:
            snackbar.info(text='network connection refreshed')

    def on_identity_backup_result(self, resp, destination_filepath):
        if _Debug:
            print('MyIDScreen.on_identity_backup_result', destination_filepath, resp)
        if not websock.is_ok(resp):
            snackbar.error(text='identity backup failed: %s' % websock.response_err(resp))
        else:
            snackbar.success(text='key file created: %s' % destination_filepath)

    def on_process_stop_result_start_engine(self, resp):
        if _Debug:
            print('MyIDScreen.on_process_stop_result_start_engine', resp)
        self.app().start_engine()
        snackbar.info(text='BitDust node process restarted')

    def on_process_stop_result_erase_my_id(self, *args):
        if _Debug:
            print('MyIDScreen.on_process_stop_result_erase_my_id', args)
        home_folder_path = os.path.join(os.path.expanduser('~'), '.bitdust')
        if system.is_android():
            home_folder_path = os.path.join('/storage/emulated/0/', '.bitdust')
        system.rmdir_recursive(os.path.join(home_folder_path, 'metadata'), ignore_errors=False)
        system.rmdir_recursive(os.path.join(home_folder_path, 'backups'), ignore_errors=True)
        system.rmdir_recursive(os.path.join(home_folder_path, 'config'), ignore_errors=True)
        system.rmdir_recursive(os.path.join(home_folder_path, 'identitycache'), ignore_errors=True)
        system.rmdir_recursive(os.path.join(home_folder_path, 'identityhistory'), ignore_errors=True)
        system.rmdir_recursive(os.path.join(home_folder_path, 'keys'), ignore_errors=True)
        system.rmdir_recursive(os.path.join(home_folder_path, 'messages'), ignore_errors=True)
        system.rmdir_recursive(os.path.join(home_folder_path, 'servicedata'), ignore_errors=True)
        system.rmdir_recursive(os.path.join(home_folder_path, 'suppliers'), ignore_errors=True)
        system.rmdir_recursive(os.path.join(home_folder_path, 'customers'), ignore_errors=True)
        system.rmdir_recursive(os.path.join(home_folder_path, 'temp'), ignore_errors=True)
        snackbar.info(text='private key erased')
        self.app().start_engine()
