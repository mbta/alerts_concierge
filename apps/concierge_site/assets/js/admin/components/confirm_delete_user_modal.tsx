import * as React from "react";
import User from "../interfaces/user";
import { format as formatPhoneNumber } from "../formatters/phone_number";

interface ConfirmDeleteUserModalProps {
  user: User;
  deleteUser: () => any;
  cancelDelete: () => any;
}

const userDetails = (user: User) => {
  if (!user)
    return null;

  return (
    <p className="delete-user-confirmation-modal--user-details">
      {user.email}
      <br />
      {formatPhoneNumber(user.phoneNumber)}
    </p>
  );
}

export const ConfirmDeleteUserModal = (props: ConfirmDeleteUserModalProps) => {
  const { user, deleteUser, cancelDelete } = props;
  const showClass = user ? 'show' : '';

  return (
    <div>
      <div
        className={`delete-user-confirmation-modal modal ${showClass}`}
        tabIndex={-1}
        role="dialog"
        aria-labelledby="exampleModalLabel"
        aria-hidden="true"
      >
        <div className="modal-dialog" role="document">
          <div className="modal-content">
            <div className="modal-body">
              {userDetails(user)}

              <p>
                Are you sure you want to delete this account?
          </p>
            </div>

            <div className="modal-footer">
              <button type="button" className="btn btn-outline-primary" onClick={cancelDelete}>
                No, cancel
              </button>
              <button type="button" className="btn btn-primary" onClick={deleteUser}>
                Yes, delete
              </button>
            </div>
          </div>
        </div>
      </div>
      <div className={`delete-user-confirmation-modal--backdrop modal-backdrop ${showClass}`}></div>
    </div>
  );
};
